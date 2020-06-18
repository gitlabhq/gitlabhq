# frozen_string_literal: true

module IncidentManagement
  class ProcessPrometheusAlertWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    queue_namespace :incident_management
    feature_category :incident_management
    worker_resource_boundary :cpu

    def perform(project_id, alert_hash)
      project = find_project(project_id)
      return unless project

      parsed_alert = Gitlab::Alerting::Alert.new(project: project, payload: alert_hash)
      event = find_prometheus_alert_event(parsed_alert)

      if event&.resolved?
        issue = event.related_issues.order_created_at_desc.detect(&:opened?)

        close_issue(project, issue)
      else
        issue = create_issue(project, alert_hash)

        relate_issue_to_event(event, issue)
      end
    end

    private

    def find_project(project_id)
      Project.find_by_id(project_id)
    end

    def find_prometheus_alert_event(alert)
      if alert.gitlab_managed?
        find_gitlab_managed_event(alert)
      else
        find_self_managed_event(alert)
      end
    end

    def find_gitlab_managed_event(alert)
      PrometheusAlertEvent.find_by_payload_key(alert.gitlab_fingerprint)
    end

    def find_self_managed_event(alert)
      SelfManagedPrometheusAlertEvent.find_by_payload_key(alert.gitlab_fingerprint)
    end

    def create_issue(project, alert)
      IncidentManagement::CreateIssueService
        .new(project, alert)
        .execute
        .dig(:issue)
    end

    def close_issue(project, issue)
      return if issue.blank? || issue.closed?

      processed_issue = Issues::CloseService
                      .new(project, User.alert_bot)
                      .execute(issue, system_note: false)

      SystemNoteService.auto_resolve_prometheus_alert(issue, project, User.alert_bot) if processed_issue.reset.closed?
    end

    def relate_issue_to_event(event, issue)
      return unless event && issue

      if event.related_issues.exclude?(issue)
        event.related_issues << issue
      end
    end
  end
end
