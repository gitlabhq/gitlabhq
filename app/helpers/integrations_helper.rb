# frozen_string_literal: true

module IntegrationsHelper
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

  def scoped_integrations_path
    if @project.present?
      project_settings_integrations_path(@project)
    elsif @group.present?
      group_settings_integrations_path(@group)
    else
      integrations_admin_application_settings_path
    end
  end

  def scoped_integration_path(integration)
    if @project.present?
      project_service_path(@project, integration)
    elsif @group.present?
      group_settings_integration_path(@group, integration)
    else
      admin_application_settings_integration_path(integration)
    end
  end

  def scoped_edit_integration_path(integration)
    if @project.present?
      edit_project_service_path(@project, integration)
    elsif @group.present?
      edit_group_settings_integration_path(@group, integration)
    else
      edit_admin_application_settings_integration_path(integration)
    end
  end

  def scoped_test_integration_path(integration)
    if @project.present?
      test_project_service_path(@project, integration)
    elsif @group.present?
      test_group_settings_integration_path(@group, integration)
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

  def integration_form_data(integration, group: nil)
    form_data = {
      id: integration.id,
      show_active: integration.show_active_box?.to_s,
      activated: (integration.active || integration.new_record?).to_s,
      type: integration.to_param,
      merge_request_events: integration.merge_requests_events.to_s,
      commit_events: integration.commit_events.to_s,
      enable_comments: integration.comment_on_event_enabled.to_s,
      comment_detail: integration.comment_detail,
      learn_more_path: integrations_help_page_path,
      trigger_events: trigger_events_for_integration(integration),
      fields: fields_for_integration(integration),
      inherit_from_id: integration.inherit_from_id,
      integration_level: integration_level(integration),
      editable: integration.editable?.to_s,
      cancel_path: scoped_integrations_path,
      can_test: integration.testable?.to_s,
      test_path: scoped_test_integration_path(integration),
      reset_path: scoped_reset_integration_path(integration, group: group)
    }

    if integration.is_a?(Integrations::Jira)
      form_data[:jira_issue_transition_automatic] = integration.jira_issue_transition_automatic
      form_data[:jira_issue_transition_id] = integration.jira_issue_transition_id
    end

    form_data
  end

  def integration_list_data(integrations)
    {
      integrations: integrations.map { |i| serialize_integration(i) }.to_json
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

  def jira_issue_breadcrumb_link(issue_reference)
    link_to '', { class: 'gl-display-flex gl-align-items-center gl-white-space-nowrap' } do
      icon = image_tag image_path('illustrations/logos/jira.svg'), width: 15, height: 15, class: 'gl-mr-2'
      [icon, issue_reference].join.html_safe
    end
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
    end
  end

  def trigger_events_for_integration(integration)
    ServiceEventSerializer.new(service: integration).represent(integration.configurable_events).to_json
  end

  def fields_for_integration(integration)
    ServiceFieldSerializer.new(service: integration).represent(integration.global_fields).to_json
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

  def serialize_integration(integration)
    {
      active: integration.operating?,
      title: integration.title,
      description: integration.description,
      updated_at: integration.updated_at,
      edit_path: scoped_edit_integration_path(integration),
      name: integration.to_param
    }
  end
end

IntegrationsHelper.prepend_mod_with('IntegrationsHelper')

# The methods in `EE::IntegrationsHelper` should be available as both instance and
# class methods.
IntegrationsHelper.extend_mod_with('IntegrationsHelper')
