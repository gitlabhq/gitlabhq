# frozen_string_literal: true

module IntegrationsHelper
  # rubocop:disable Metrics/CyclomaticComplexity
  def integration_event_title(event)
    case event
    when "push", "push_events"
      _("Push")
    when "tag_push", "tag_push_events"
      _("Tag push")
    when "note", "note_events"
      _("Note")
    when "confidential_note", "confidential_note_events"
      _("Confidential note")
    when "issue", "issue_events"
      _("Issue")
    when "confidential_issue", "confidential_issue_events"
      _("Confidential issue")
    when "merge_request", "merge_request_events"
      _("Merge request")
    when "pipeline", "pipeline_events"
      _("Pipeline")
    when "wiki_page", "wiki_page_events"
      _("Wiki page")
    when "commit", "commit_events"
      _("Commit")
    when "deployment"
      _("Deployment")
    when "alert"
      _("Alert")
    when "incident"
      _("Incident")
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def integration_event_description(integration, event)
    case integration
    when Integrations::Jira
      jira_integration_event_description(event)
    when Integrations::Teamcity
      teamcity_integration_event_description(event)
    else
      default_integration_event_description(event)
    end
  end

  def integration_event_field_name(event)
    event = event.pluralize if %w[merge_request issue confidential_issue].include?(event)
    "#{event}_events"
  end

  def scoped_integrations_path(project: nil, group: nil)
    if project.present?
      project_settings_integrations_path(project)
    elsif group.present?
      group_settings_integrations_path(group)
    else
      integrations_admin_application_settings_path
    end
  end

  def scoped_integration_path(integration, project: nil, group: nil)
    if project.present?
      project_settings_integration_path(project, integration)
    elsif group.present?
      group_settings_integration_path(group, integration)
    else
      admin_application_settings_integration_path(integration)
    end
  end

  def scoped_edit_integration_path(integration, project: nil, group: nil)
    if project.present?
      edit_project_settings_integration_path(project, integration)
    elsif group.present?
      edit_group_settings_integration_path(group, integration)
    else
      edit_admin_application_settings_integration_path(integration)
    end
  end

  def scoped_overrides_integration_path(integration, options = {})
    overrides_admin_application_settings_integration_path(integration, options)
  end

  def scoped_test_integration_path(integration, project: nil, group: nil)
    if project.present?
      test_project_settings_integration_path(project, integration)
    elsif group.present?
      test_group_settings_integration_path(group, integration)
    else
      test_admin_application_settings_integration_path(integration)
    end
  end

  def scoped_reset_integration_path(integration, group: nil)
    return '' unless integration.persisted?

    if group.present?
      reset_group_settings_integration_path(group, integration)
    else
      reset_admin_application_settings_integration_path(integration)
    end
  end

  def integration_form_data(integration, project: nil, group: nil)
    form_data = {
      id: integration.id,
      project_id: integration.project_id,
      group_id: integration.group_id,
      manual_activation: integration.manual_activation?.to_s,
      activated: (integration.active || (integration.new_record? && integration.activate_disabled_reason.nil?)).to_s,
      activate_disabled: integration.activate_disabled_reason.present?.to_s,
      type: integration.to_param,
      merge_request_events: integration.merge_requests_events.to_s,
      commit_events: integration.commit_events.to_s,
      enable_comments: integration.comment_on_event_enabled.to_s,
      comment_detail: integration.comment_detail,
      learn_more_path: integrations_help_page_path,
      about_pricing_url: Gitlab::Saas.about_pricing_url,
      trigger_events: trigger_events_for_integration(integration),
      sections: integration.sections.to_json,
      fields: fields_for_integration(integration),
      inherit_from_id: integration.inherit_from_id,
      integration_level: integration_level(integration),
      editable: integration.editable?.to_s,
      cancel_path: scoped_integrations_path(project: project, group: group),
      can_test: integration.testable?.to_s,
      test_path: scoped_test_integration_path(integration, project: project, group: group),
      reset_path: scoped_reset_integration_path(integration, group: group),
      form_path: scoped_integration_path(integration, project: project, group: group),
      redirect_to: request.referer
    }

    if integration.is_a?(Integrations::Jira)
      form_data[:jira_issue_transition_automatic] = integration.jira_issue_transition_automatic
      form_data[:jira_issue_transition_id] = integration.jira_issue_transition_id
    end

    if integration.is_a?(::Integrations::GitlabSlackApplication)
      form_data[:upgrade_slack_url] = add_to_slack_link(integration.parent, slack_app_id)
      form_data[:should_upgrade_slack] = integration.upgrade_needed?.to_s
    end

    form_data
  end

  def integration_overrides_data(integration, project: nil, group: nil)
    {
      edit_path: scoped_edit_integration_path(integration, project: project, group: group),
      overrides_path: scoped_overrides_integration_path(integration, format: :json)
    }
  end

  def integration_list_data(integrations, group: nil, project: nil)
    {
      integrations: integrations.map { |i| serialize_integration(i, group: group, project: project) }.to_json
    }
  end

  def integrations_help_page_path
    help_page_path('administration/settings/project_integration_management.md')
  end

  def project_jira_issues_integration?
    false
  end

  def instance_level_integrations?
    !Gitlab.com?
  end

  def integration_issue_type(issue_type)
    issue_type_i18n_map = {
      'issue' => _('Issue'),
      'incident' => _('Incident'),
      'test_case' => _('Test case'),
      'requirement' => _('Requirement'),
      'task' => _('Task'),
      'ticket' => _('Service Desk Ticket')
    }

    issue_type_i18n_map[issue_type] || issue_type
  end

  def integration_todo_target_type(target_type)
    target_type_i18n_map = {
      'Commit' => _('Commit'),
      'Issue' => _('Issue'),
      'MergeRequest' => _('Merge Request'),
      'Epic' => _('Epic'),
      DesignManagement::Design.name => _('design'),
      AlertManagement::Alert.name => _('alert')
    }

    target_type_i18n_map[target_type] || target_type
  end

  def integration_webhook_event_human_name(event)
    event_i18n_map = {
      confidential_issues_events: s_('Webhooks|Confidential issues events'),
      confidential_note_events: s_('Webhooks|Confidential comments'),
      deployment_events: s_('Webhooks|Deployment events'),
      feature_flag_events: s_('Webhooks|Feature flag events'),
      issues_events: s_('Webhooks|Issues events'),
      job_events: s_('Webhooks|Job events'),
      member_events: s_('Webhooks|Member events'),
      merge_requests_events: s_('Webhooks|Merge request events'),
      note_events: _('Comments'),
      pipeline_events: s_('Webhooks|Pipeline events'),
      project_events: s_('Webhooks|Project events'),
      push_events: _('Push events'),
      releases_events: s_('Webhooks|Releases events'),
      repository_update_events: _('Repository update events'),
      resource_access_token_events: s_('Webhooks|Project or group access token events'),
      subgroup_events: s_('Webhooks|Subgroup events'),
      tag_push_events: s_('Webhooks|Tag push events'),
      wiki_page_events: s_('Webhooks|Wiki page events'),
      vulnerability_events: s_('Webhooks|Vulnerability events')
    }

    event_i18n_map[event] || event.to_s.humanize
  end

  def add_to_slack_link(parent, slack_app_id)
    query = {
      scope: SlackIntegration::SCOPES.join(','),
      client_id: slack_app_id,
      redirect_uri: add_to_slack_link_redirect_url(parent),
      state: form_authenticity_token
    }

    Gitlab::Utils.add_url_parameters(
      Integrations::SlackInstallation::BaseService::SLACK_AUTHORIZE_URL,
      query
    )
  end

  def slack_integration_destroy_path(parent)
    case parent
    when Project
      project_settings_slack_path(parent)
    when Group
      group_settings_slack_path(parent)
    when nil
      admin_application_settings_slack_path
    end
  end

  def gitlab_slack_application_data(projects)
    {
      projects: (projects || []).to_json(only: [:id, :name], methods: [:avatar_url, :name_with_namespace]),
      sign_in_path: new_session_path(:user, redirect_to_referer: 'yes'),
      is_signed_in: current_user.present?.to_s,
      slack_link_path: slack_link_profile_slack_path,
      gitlab_logo_path: image_path('illustrations/gitlab_logo.svg'),
      slack_logo_path: image_path('illustrations/slack_logo.svg')
    }
  end

  extend self

  private

  def add_to_slack_link_redirect_url(parent)
    case parent
    when Project
      slack_auth_project_settings_slack_url(parent)
    when Group
      slack_auth_group_settings_slack_url(parent)
    when nil
      slack_auth_admin_application_settings_slack_url
    end
  end

  def jira_integration_event_description(event)
    case event
    when "merge_request", "merge_request_events"
      s_("JiraService|Jira comments are created when an issue is referenced in a merge request.")
    when "commit", "commit_events"
      s_("JiraService|Jira comments are created when an issue is referenced in a commit.")
    end
  end

  def teamcity_integration_event_description(event)
    case event
    when 'push', 'push_events'
      s_('TeamcityIntegration|Trigger TeamCity CI after every push to the repository, except branch delete')
    when 'merge_request', 'merge_request_events'
      s_('TeamcityIntegration|Trigger TeamCity CI after a merge request has been created or updated')
    end
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def default_integration_event_description(event)
    case event
    when "push", "push_events"
      s_("ProjectService|Trigger event for pushes to the repository.")
    when "tag_push", "tag_push_events"
      s_("ProjectService|Trigger event for new tags pushed to the repository.")
    when "note", "note_events"
      s_("ProjectService|Trigger event for new comments.")
    when "confidential_note", "confidential_note_events"
      s_("ProjectService|Trigger event for new comments on confidential issues.")
    when "issue", "issue_events", "issues_events"
      s_("ProjectService|Trigger event when an issue is created, updated, or closed.")
    when "confidential_issue", "confidential_issue_events", "confidential_issues_events"
      s_("ProjectService|Trigger event when a confidential issue is created, updated, or closed.")
    when "merge_request", "merge_request_events", "merge_requests_events"
      s_("ProjectService|Trigger event when a merge request is created, updated, or merged.")
    when "pipeline", "pipeline_events"
      s_("ProjectService|Trigger event when a pipeline status changes.")
    when "wiki_page", "wiki_page_events"
      s_("ProjectService|Trigger event when a wiki page is created or updated.")
    when "commit", "commit_events"
      s_("ProjectService|Trigger event when a commit is created or updated.")
    when "deployment", "deployment_events"
      s_("ProjectService|Trigger event when a deployment starts or finishes.")
    when "alert", "alert_events"
      s_("ProjectService|Trigger event when a new, unique alert is recorded.")
    when "incident", "incident_events"
      s_("ProjectService|Trigger event when an incident is created.")
    when "build_events"
      s_("ProjectService|Trigger event when a build is created.")
    when "archive_trace_events"
      s_('When enabled, job logs are collected by Datadog and displayed along with pipeline execution traces.')
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def trigger_events_for_integration(integration)
    Integrations::EventSerializer.new(integration: integration).represent(integration.configurable_events).to_json
  end

  def fields_for_integration(integration)
    Integrations::FieldSerializer.new(integration: integration).represent(integration.form_fields).to_json
  end

  def integration_level(integration)
    if integration.instance_level?
      'instance'
    elsif integration.group_level?
      'group'
    else
      'project'
    end
  end

  def serialize_integration(integration, group: nil, project: nil)
    {
      id: integration.id,
      active: integration.activated?,
      configured: integration.persisted?,
      title: integration.title,
      description: integration.description,
      updated_at: integration.updated_at,
      edit_path: scoped_edit_integration_path(integration, group: group, project: project),
      name: integration.to_param,
      icon: integration.try(:avatar_url)
    }
  end
end

IntegrationsHelper.prepend_mod_with('IntegrationsHelper')

# The methods in `EE::IntegrationsHelper` should be available as both instance and
# class methods.
IntegrationsHelper.extend_mod_with('IntegrationsHelper')
