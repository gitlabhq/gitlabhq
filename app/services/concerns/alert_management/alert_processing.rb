# frozen_string_literal: true

module AlertManagement
  # Module to support the processing of new alert payloads
  # from various sources. Payloads may be for new alerts,
  # existing alerts, or acting as a resolving alert.
  #
  # Performs processing-related tasks, such as creating system
  # notes, creating or resolving related issues, and notifying
  # stakeholders of the alert.
  #
  # Requires #project [Project] and #payload [Hash] methods
  # to be defined.
  module AlertProcessing
    include BaseServiceUtility
    include Gitlab::Utils::StrongMemoize
    include ::IncidentManagement::Settings

    # Updates or creates alert from payload for project
    # including system notes
    def process_alert
      alert.persisted? ? process_existing_alert : process_new_alert
    end

    # Creates or closes issue for alert and notifies stakeholders
    def complete_post_processing_tasks
      process_incident_issues if process_issues?
      send_alert_email if send_email? && notifying_alert?
    end

    def process_existing_alert
      resolving_alert? ? process_resolved_alert : process_firing_alert
    end

    def process_resolved_alert
      SystemNoteService.log_resolving_alert(alert, alert_source)

      if alert.resolve(incoming_payload.ends_at)
        SystemNoteService.change_alert_status(alert, Users::Internal.alert_bot)

        close_issue(alert.issue_id) if auto_close_incident?
      end
    end

    def process_firing_alert
      alert.register_new_event!
    end

    def close_issue(issue_id)
      return unless issue_id

      ::IncidentManagement::CloseIncidentWorker.perform_async(issue_id)
    end

    def process_new_alert
      return if resolving_alert?

      if alert.save
        alert.execute_integrations
        SystemNoteService.create_new_alert(alert, alert_source)
      elsif alert.errors[:fingerprint].any?
        refind_and_increment_alert
      else
        logger.warn(
          message: "Unable to create AlertManagement::Alert",
          project_id: project.id,
          alert_errors: alert.errors.messages,
          alert_source: alert_source
        )
      end
    rescue ActiveRecord::RecordNotUnique
      refind_and_increment_alert
    end

    def process_incident_issues
      return if alert.issue_id || alert.resolved?

      ::IncidentManagement::ProcessAlertWorkerV2.perform_async(alert.id)
    end

    def send_alert_email
      notification_service
        .async
        .prometheus_alerts_fired(project, [alert])
    end

    def incoming_payload
      strong_memoize(:incoming_payload) do
        Gitlab::AlertManagement::Payload.parse(project, payload.to_h, integration: integration)
      end
    end

    def alert
      strong_memoize(:alert) do
        find_existing_alert || build_new_alert
      end
    end

    def find_existing_alert
      return unless incoming_payload.gitlab_fingerprint

      AlertManagement::Alert.find_unresolved_alert(project, incoming_payload.gitlab_fingerprint)
    end

    def build_new_alert
      AlertManagement::Alert.new(**incoming_payload.alert_params, ended_at: nil)
    end

    def refind_and_increment_alert
      clear_memoization(:alert)

      process_firing_alert
    end

    def resolving_alert?
      incoming_payload.resolved?
    end

    def notifying_alert?
      alert.triggered? || alert.resolved?
    end

    def alert_source
      incoming_payload.source
    end

    def logger
      @logger ||= Gitlab::AppLogger
    end
  end
end

AlertManagement::AlertProcessing.prepend_mod
