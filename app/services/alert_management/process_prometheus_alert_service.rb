# frozen_string_literal: true

module AlertManagement
  class ProcessPrometheusAlertService < BaseService
    include Gitlab::Utils::StrongMemoize

    def execute
      return bad_request unless parsed_alert.valid?

      process_alert_management_alert

      ServiceResponse.success
    end

    private

    delegate :firing?, :resolved?, :gitlab_fingerprint, :ends_at, to: :parsed_alert

    def parsed_alert
      strong_memoize(:parsed_alert) do
        Gitlab::Alerting::Alert.new(project: project, payload: params)
      end
    end

    def process_alert_management_alert
      process_firing_alert_management_alert if firing?
      process_resolved_alert_management_alert if resolved?
    end

    def process_firing_alert_management_alert
      if am_alert.present?
        am_alert.register_new_event!
        reset_alert_management_alert_status
      else
        create_alert_management_alert
      end
    end

    def reset_alert_management_alert_status
      return if am_alert.trigger

      logger.warn(
        message: 'Unable to update AlertManagement::Alert status to triggered',
        project_id: project.id,
        alert_id: am_alert.id
      )
    end

    def create_alert_management_alert
      am_alert = AlertManagement::Alert.new(am_alert_params.merge(ended_at: nil))
      if am_alert.save
        am_alert.execute_services
        return
      end

      logger.warn(
        message: 'Unable to create AlertManagement::Alert',
        project_id: project.id,
        alert_errors: am_alert.errors.messages
      )
    end

    def am_alert_params
      Gitlab::AlertManagement::AlertParams.from_prometheus_alert(project: project, parsed_alert: parsed_alert)
    end

    def process_resolved_alert_management_alert
      return if am_alert.blank?
      return if am_alert.resolve(ends_at)

      logger.warn(
        message: 'Unable to update AlertManagement::Alert status to resolved',
        project_id: project.id,
        alert_id: am_alert.id
      )
    end

    def logger
      @logger ||= Gitlab::AppLogger
    end

    def am_alert
      @am_alert ||= AlertManagement::Alert.for_fingerprint(project, gitlab_fingerprint).first
    end

    def bad_request
      ServiceResponse.error(message: 'Bad Request', http_status: :bad_request)
    end
  end
end
