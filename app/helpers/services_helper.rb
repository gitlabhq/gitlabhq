# frozen_string_literal: true

module ServicesHelper
  def service_event_description(event)
    case event
    when "push", "push_events"
      "Event will be triggered by a push to the repository"
    when "tag_push", "tag_push_events"
      "Event will be triggered when a new tag is pushed to the repository"
    when "note", "note_events"
      "Event will be triggered when someone adds a comment"
    when "confidential_note", "confidential_note_events"
      "Event will be triggered when someone adds a comment on a confidential issue"
    when "issue", "issue_events"
      "Event will be triggered when an issue is created/updated/closed"
    when "confidential_issue", "confidential_issues_events"
      "Event will be triggered when a confidential issue is created/updated/closed"
    when "merge_request", "merge_request_events"
      "Event will be triggered when a merge request is created/updated/merged"
    when "pipeline", "pipeline_events"
      "Event will be triggered when a pipeline status changes"
    when "wiki_page", "wiki_page_events"
      "Event will be triggered when a wiki page is created/updated"
    when "commit", "commit_events"
      "Event will be triggered when a commit is created/updated"
    end
  end

  def service_event_field_name(event)
    event = event.pluralize if %w[merge_request issue confidential_issue].include?(event)
    "#{event}_events"
  end

  def service_event_action_field_name(action)
    "#{action}_on_event_enabled"
  end

  def event_action_title(action)
    case action
    when "comment"
      s_("ProjectService|Comment")
    else
      action.humanize
    end
  end

  def event_action_description(action)
    case action
    when "comment"
      s_("ProjectService|Comment will be posted on each event")
    end
  end

  def service_save_button
    button_tag(class: 'btn btn-success', type: 'submit', data: { qa_selector: 'save_changes_button' }) do
      icon('spinner spin', class: 'hidden js-btn-spinner') +
        content_tag(:span, 'Save changes', class: 'js-btn-label')
    end
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
      test_project_settings_integration_path(@project, integration)
    elsif @group.present?
      test_group_settings_integration_path(@group, integration)
    else
      test_admin_application_settings_integration_path(integration)
    end
  end

  extend self
end

ServicesHelper.prepend_if_ee('EE::ServicesHelper') # rubocop: disable Cop/InjectEnterpriseEditionModule

# The methods in `EE::ServicesHelper` should be available as both instance and
# class methods.
ServicesHelper.extend_if_ee('EE::ServicesHelper')
