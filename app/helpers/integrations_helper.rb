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
      show_active: integration.show_active_box?.to_s,
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
    help_page_path('user/admin_area/settings/project_integration_management')
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
      'task' => _('Task')
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
      repository_update_events: _('Repository update events'),
      push_events: _('Push events'),
      tag_push_events: s_('Webhooks|Tag push events'),
      note_events: _('Comments'),
      confidential_note_events: s_('Webhooks|Confidential comments'),
      issues_events: s_('Webhooks|Issues events'),
      confidential_issues_events: s_('Webhooks|Confidential issues events'),
      subgroup_events: s_('Webhooks|Subgroup events'),
      member_events: s_('Webhooks|Member events'),
      merge_requests_events: s_('Webhooks|Merge request events'),
      job_events: s_('Webhooks|Job events'),
      pipeline_events: s_('Webhooks|Pipeline events'),
      wiki_page_events: s_('Webhooks|Wiki page events'),
      deployment_events: s_('Webhooks|Deployment events'),
      feature_flag_events: s_('Webhooks|Feature flag events'),
      releases_events: s_('Webhooks|Releases events')
    }

    event_i18n_map[event] || event.to_s.humanize
  end

  extend self

  private

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
    when "issue", "issue_events"
      s_("ProjectService|Trigger event when an issue is created, updated, or closed.")
    when "confidential_issue", "confidential_issue_events"
      s_("ProjectService|Trigger event when a confidential issue is created, updated, or closed.")
    when "merge_request", "merge_request_events"
      s_("ProjectService|Trigger event when a merge request is created, updated, or merged.")
    when "pipeline", "pipeline_events"
      s_("ProjectService|Trigger event when a pipeline status changes.")
    when "wiki_page", "wiki_page_events"
      s_("ProjectService|Trigger event when a wiki page is created or updated.")
    when "commit", "commit_events"
      s_("ProjectService|Trigger event when a commit is created or updated.")
    when "deployment"
      s_("ProjectService|Trigger event when a deployment starts or finishes.")
    when "alert"
      s_("ProjectService|Trigger event when a new, unique alert is recorded.")
    when "incident"
      s_("ProjectService|Trigger event when an incident is created.")
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
      active: integration.operating?,
      title: integration.title,
      description: integration.description,
      updated_at: integration.updated_at,
      edit_path: scoped_edit_integration_path(integration, group: group, project: project),
      name: integration.to_param
    }
  end
end

IntegrationsHelper.prepend_mod_with('IntegrationsHelper')

# The methods in `EE::IntegrationsHelper` should be available as both instance and
# class methods.
IntegrationsHelper.extend_mod_with('IntegrationsHelper')
