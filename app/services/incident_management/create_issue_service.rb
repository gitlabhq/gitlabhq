# frozen_string_literal: true

module IncidentManagement
  class CreateIssueService < BaseService
    include Gitlab::Utils::StrongMemoize
    include IncidentManagement::Settings

    attr_reader :alert

    def initialize(project, alert)
      super(project, User.alert_bot)
      @alert = alert
    end

    def execute
      return error('setting disabled') unless incident_management_setting.create_issue?
      return error('invalid alert') unless alert_presenter.valid?

      result = create_incident
      return error(result.message, result.payload[:issue]) unless result.success?

      result
    end

    private

    def create_incident
      ::IncidentManagement::Incidents::CreateService.new(
        project,
        current_user,
        title: issue_title,
        description: issue_description
      ).execute
    end

    def issue_title
      alert_presenter.full_title
    end

    def issue_description
      horizontal_line = "\n\n---\n\n"

      [
        alert_summary,
        alert_markdown,
        issue_template_content
      ].compact.join(horizontal_line)
    end

    def alert_summary
      alert_presenter.issue_summary_markdown
    end

    def alert_markdown
      alert_presenter.alert_markdown
    end

    def alert_presenter
      strong_memoize(:alert_presenter) do
        Gitlab::Alerting::Alert.for_alert_management_alert(project: project, alert: alert).present
      end
    end

    def issue_template_content
      incident_management_setting.issue_template_content
    end

    def error(message, issue = nil)
      log_error(%{Cannot create incident issue for "#{project.full_name}": #{message}})

      ServiceResponse.error(payload: { issue: issue }, message: message)
    end
  end
end
