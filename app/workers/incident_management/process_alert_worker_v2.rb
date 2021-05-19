# frozen_string_literal: true

module IncidentManagement
  class ProcessAlertWorkerV2 # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    queue_namespace :incident_management
    feature_category :incident_management

    idempotent!

    def perform(alert_id)
      return unless alert_id

      alert = find_alert(alert_id)
      return unless alert

      result = create_issue_for(alert)
      return if result.success?

      log_warning(alert, result)
    end

    private

    def find_alert(alert_id)
      AlertManagement::Alert.find_by_id(alert_id)
    end

    def create_issue_for(alert)
      AlertManagement::CreateAlertIssueService
        .new(alert, User.alert_bot)
        .execute
    end

    def log_warning(alert, result)
      issue_id = result.payload[:issue]&.id

      Gitlab::AppLogger.warn(
        message: 'Cannot process an Incident',
        issue_id: issue_id,
        alert_id: alert.id,
        errors: result.message
      )
    end
  end
end
