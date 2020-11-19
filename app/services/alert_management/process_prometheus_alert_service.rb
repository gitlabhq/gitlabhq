# frozen_string_literal: true

module AlertManagement
  class ProcessPrometheusAlertService < BaseService
    include Gitlab::Utils::StrongMemoize
    include ::IncidentManagement::Settings

    def execute
      return bad_request unless incoming_payload.has_required_attributes?

      process_alert_management_alert
      return bad_request unless alert.persisted?

      process_incident_issues if process_issues?
      send_alert_email if send_email?

      ServiceResponse.success
    end

    private

    def process_alert_management_alert
      if incoming_payload.resolved?
        process_resolved_alert_management_alert
      else
        process_firing_alert_management_alert
      end
    end

    def process_firing_alert_management_alert
      if alert.persisted?
        alert.register_new_event!
        reset_alert_management_alert_status
      else
        create_alert_management_alert
      end
    end

    def reset_alert_management_alert_status
      return if alert.trigger

      logger.warn(
        message: 'Unable to update AlertManagement::Alert status to triggered',
        project_id: project.id,
        alert_id: alert.id
      )
    end

    def create_alert_management_alert
      if alert.save
        alert.execute_services
        SystemNoteService.create_new_alert(alert, Gitlab::AlertManagement::Payload::MONITORING_TOOLS[:prometheus])
        return
      end

      logger.warn(
        message: 'Unable to create AlertManagement::Alert',
        project_id: project.id,
        alert_errors: alert.errors.messages
      )
    end

    def process_resolved_alert_management_alert
      return unless alert.persisted?
      return unless auto_close_incident?

      if alert.resolve(incoming_payload.ends_at)
        close_issue(alert.issue)
        return
      end

      logger.warn(
        message: 'Unable to update AlertManagement::Alert status to resolved',
        project_id: project.id,
        alert_id: alert.id
      )
    end

    def close_issue(issue)
      return if issue.blank? || issue.closed?

      Issues::CloseService
        .new(project, User.alert_bot)
        .execute(issue, system_note: false)

      SystemNoteService.auto_resolve_prometheus_alert(issue, project, User.alert_bot) if issue.reset.closed?
    end

    def process_incident_issues
      return if alert.issue || alert.resolved?

      IncidentManagement::ProcessAlertWorker.perform_async(nil, nil, alert.id)
    end

    def send_alert_email
      notification_service
        .async
        .prometheus_alerts_fired(project, [alert])
    end

    def logger
      @logger ||= Gitlab::AppLogger
    end

    def alert
      strong_memoize(:alert) do
        existing_alert || new_alert
      end
    end

    def existing_alert
      strong_memoize(:existing_alert) do
        AlertManagement::Alert.not_resolved.for_fingerprint(project, incoming_payload.gitlab_fingerprint).first
      end
    end

    def new_alert
      strong_memoize(:new_alert) do
        AlertManagement::Alert.new(
          **incoming_payload.alert_params,
          ended_at: nil
        )
      end
    end

    def incoming_payload
      strong_memoize(:incoming_payload) do
        Gitlab::AlertManagement::Payload.parse(
          project,
          params,
          monitoring_tool: Gitlab::AlertManagement::Payload::MONITORING_TOOLS[:prometheus]
        )
      end
    end

    def bad_request
      ServiceResponse.error(message: 'Bad Request', http_status: :bad_request)
    end
  end
end
