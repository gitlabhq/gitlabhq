# frozen_string_literal: true

module AlertManagement
  class AlertPresenter < Gitlab::View::Presenter::Delegated
    include IncidentManagement::Settings

    presents ::AlertManagement::Alert
    delegator_override_with Gitlab::Utils::StrongMemoize # This module inclusion is expected. See https://gitlab.com/gitlab-org/gitlab/-/issues/352884.

    MARKDOWN_LINE_BREAK = "  \n"
    HORIZONTAL_LINE = "\n\n---\n\n"

    delegate :runbook, to: :parsed_payload

    def initialize(alert, **attributes)
      super

      @alert = alert
      @project = alert.project
    end

    def issue_description
      [
        issue_summary_markdown,
        alert_markdown,
        incident_management_setting.issue_template_content
      ].compact.join(HORIZONTAL_LINE)
    end

    def start_time
      started_at&.strftime('%d %B %Y, %-l:%M%p (%Z)')
    end

    delegator_override :details_url
    def details_url
      details_project_alert_management_url(project, alert.iid)
    end

    def details
      Gitlab::Utils::InlineHash.merge_keys(payload)
    end

    def show_incident_issues_link?
      project.incident_management_setting&.create_issue?
    end

    def incident_issues_link
      project_incidents_url(project)
    end

    def email_title
      [environment&.name, title].compact.join(': ')
    end

    private

    attr_reader :alert, :project

    delegate :alert_markdown, :full_query, to: :parsed_payload

    def issue_summary_markdown
      <<~MARKDOWN.chomp
        #{metadata_list}\n
      MARKDOWN
    end

    def metadata_list
      metadata = []

      metadata << list_item('Start time', start_time)
      metadata << list_item('Severity', severity)
      metadata << list_item('full_query', backtick(full_query)) if full_query
      metadata << list_item('Service', service) if service
      metadata << list_item('Monitoring tool', monitoring_tool) if monitoring_tool
      metadata << list_item('Hosts', host_links) if hosts.any?
      metadata << list_item('Description', description) if description.present?
      metadata << list_item('GitLab alert', details_url) if details_url.present?

      metadata.join(MARKDOWN_LINE_BREAK)
    end

    def list_item(key, value)
      "**#{key}:** #{value}".strip
    end

    def backtick(value)
      "`#{value}`"
    end

    def host_links
      hosts.join(' ')
    end
  end
end

AlertManagement::AlertPresenter.prepend_mod_with('AlertManagement::AlertPresenter')
