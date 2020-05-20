# frozen_string_literal: true

module IncidentManagement
  class CreateIssueService < BaseService
    include Gitlab::Utils::StrongMemoize

    INCIDENT_LABEL = {
      title: 'incident',
      color: '#CC0033',
      description: <<~DESCRIPTION.chomp
        Denotes a disruption to IT services and \
        the associated issues require immediate attention
      DESCRIPTION
    }.freeze

    def initialize(project, params, user = User.alert_bot)
      super(project, user, params)
    end

    def execute(skip_settings_check: false)
      return error_with('setting disabled') unless skip_settings_check || incident_management_setting.create_issue?
      return error_with('invalid alert') unless alert.valid?

      issue = create_issue
      return error_with(issue_errors(issue)) unless issue.valid?

      success(issue: issue)
    end

    private

    def create_issue
      issue = do_create_issue(label_ids: issue_label_ids)

      # Create an unlabelled issue if we couldn't create the issue
      # due to labels errors.
      # See https://gitlab.com/gitlab-org/gitlab-foss/issues/65042
      if issue.errors.include?(:labels)
        log_label_error(issue)
        issue = do_create_issue
      end

      issue
    end

    def do_create_issue(**params)
      Issues::CreateService.new(
        project,
        current_user,
        title: issue_title,
        description: issue_description,
        **params
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

    def issue_label_ids
      [
        find_or_create_label(**INCIDENT_LABEL)
      ].compact.map(&:id)
    end

    def find_or_create_label(**params)
      Labels::FindOrCreateService
        .new(current_user, project, **params)
        .execute
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

    def log_label_error(issue)
      log_info <<~TEXT.chomp
        Cannot create incident issue with labels \
        #{issue.labels.map(&:title).inspect} \
        for "#{project.full_name}": #{issue.errors.full_messages.to_sentence}.
        Retrying without labels.
      TEXT
    end

    def error_with(message)
      log_error(%{Cannot create incident issue for "#{project.full_name}": #{message}})

      error(message)
    end
  end
end
