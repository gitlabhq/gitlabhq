# frozen_string_literal: true

module IncidentManagement
  class ProcessAlertWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    queue_namespace :incident_management
    feature_category :incident_management

    def perform(project_id, alert_payload, am_alert_id = nil)
      project = find_project(project_id)
      return unless project

      new_issue = create_issue(project, alert_payload)
      return unless am_alert_id && new_issue&.persisted?

      link_issue_with_alert(am_alert_id, new_issue.id)
    end

    private

    def find_project(project_id)
      Project.find_by_id(project_id)
    end

    def create_issue(project, alert_payload)
      IncidentManagement::CreateIssueService
        .new(project, alert_payload)
        .execute
        .dig(:issue)
    end

    def link_issue_with_alert(alert_id, issue_id)
      alert = AlertManagement::Alert.find_by_id(alert_id)
      return unless alert

      return if alert.update(issue_id: issue_id)

      Gitlab::AppLogger.warn(
        message: 'Cannot link an Issue with Alert',
        issue_id: issue_id,
        alert_id: alert_id,
        alert_errors: alert.errors.messages
      )
    end
  end
end
