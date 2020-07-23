# frozen_string_literal: true

module IncidentManagement
  class CreateIssueService < BaseService
    include Gitlab::Utils::StrongMemoize
    include IncidentManagement::Settings

    def initialize(project, params)
      super(project, User.alert_bot, params)
    end

    def execute
      return error('setting disabled') unless incident_management_setting.create_issue?
      return error('invalid alert') unless alert.valid?

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
      alert.full_title
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
      alert.issue_summary_markdown
    end

    def alert_markdown
      alert.alert_markdown
    end

    def alert
      strong_memoize(:alert) do
        Gitlab::Alerting::Alert.new(project: project, payload: params).present
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
