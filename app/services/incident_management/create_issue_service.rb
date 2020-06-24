# frozen_string_literal: true

module IncidentManagement
  class CreateIssueService < BaseService
    include Gitlab::Utils::StrongMemoize

    def initialize(project, params)
      super(project, User.alert_bot, params)
    end

    def execute
      return error_with('setting disabled') unless incident_management_setting.create_issue?
      return error_with('invalid alert') unless alert.valid?

      issue = create_issue
      return error_with(issue_errors(issue)) unless issue.valid?

      success(issue: issue)
    end

    private

    def create_issue
      label_result = find_or_create_incident_label

      # Create an unlabelled issue if we couldn't create the label
      # due to a race condition.
      # See https://gitlab.com/gitlab-org/gitlab-foss/issues/65042
      extra_params = label_result.success? ? { label_ids: [label_result.payload[:label].id] } : {}

      Issues::CreateService.new(
        project,
        current_user,
        title: issue_title,
        description: issue_description,
        **extra_params
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

    def find_or_create_incident_label
      IncidentManagement::CreateIncidentLabelService.new(project, current_user).execute
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

    def incident_management_setting
      strong_memoize(:incident_management_setting) do
        project.incident_management_setting ||
          project.build_incident_management_setting
      end
    end

    def issue_errors(issue)
      issue.errors.full_messages.to_sentence
    end

    def error_with(message)
      log_error(%{Cannot create incident issue for "#{project.full_name}": #{message}})

      error(message)
    end
  end
end
