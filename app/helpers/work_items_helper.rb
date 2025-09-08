# frozen_string_literal: true

module WorkItemsHelper
  include IssuesHelper

  # overridden in EE
  def work_items_data(resource_parent, current_user)
    group = extract_group(resource_parent)

    base_data(resource_parent, current_user, group).tap do |data|
      if resource_parent.is_a?(Project)
        data[:releases_path] = project_releases_path(resource_parent, format: :json)
        data[:project_import_jira_path] = project_import_jira_path(resource_parent)
        data[:can_import_work_items] = can?(current_user, :import_work_items, resource_parent).to_s
      end
    end
  end

  # overridden in EE
  def add_work_item_show_breadcrumb(resource_parent, _iid)
    path = resource_parent.is_a?(Group) ? issues_group_path(resource_parent) : project_issues_path(resource_parent)

    add_to_breadcrumbs(_('Issues'), path)
  end

  # overridden in EE
  def instance_type_new_trial_path(_group)
    self_managed_new_trial_url
  end

  private

  def extract_group(resource_parent)
    resource_parent.is_a?(Group) ? resource_parent : resource_parent.group
  end

  def base_data(resource_parent, current_user, group)
    {
      autocomplete_award_emojis_path: autocomplete_award_emojis_path,
      can_admin_label: can?(current_user, :admin_label, resource_parent).to_s,
      can_bulk_update: can?(current_user, :admin_issue, resource_parent).to_s,
      can_edit: can?(current_user, :admin_project, resource_parent).to_s,
      full_path: resource_parent.full_path,
      group_path: group&.full_path,
      issues_list_path: issues_path_for(resource_parent),
      labels_manage_path: labels_path_for(resource_parent),
      register_path: new_user_registration_path(redirect_to_referer: 'yes'),
      sign_in_path: new_session_path(:user, redirect_to_referer: 'yes'),
      new_trial_path: instance_type_new_trial_path(group),
      new_comment_template_paths: new_comment_template_paths(group).to_json,
      report_abuse_path: add_category_abuse_reports_path,
      default_branch: resource_parent.is_a?(Project) ? resource_parent.default_branch_or_main : nil,
      initial_sort: current_user&.user_preference&.issues_sort,
      is_signed_in: current_user.present?.to_s,
      show_new_work_item: can?(current_user, :create_work_item, resource_parent).to_s,
      can_create_projects: can?(current_user, :create_projects, group).to_s,
      new_project_path: new_project_path(namespace_id: group&.id),
      project_namespace_full_path:
        resource_parent.is_a?(Project) ? resource_parent.namespace.full_path : resource_parent.full_path,
      group_id: group&.id,
      time_tracking_limit_to_hours: Gitlab::CurrentSettings.time_tracking_limit_to_hours.to_s,
      can_read_crm_contact: can?(current_user, :read_crm_contact, resource_parent.crm_group).to_s,
      max_attachment_size: number_to_human_size(Gitlab::CurrentSettings.max_attachment_size.megabytes),
      can_read_crm_organization: can?(current_user, :read_crm_organization, resource_parent.crm_group).to_s,
      rss_path: rss_path_for(resource_parent),
      calendar_path: calendar_path_for(resource_parent)
    }
  end

  def issues_path_for(resource_parent)
    resource_parent.is_a?(Group) ? issues_group_path(resource_parent) : project_issues_path(resource_parent)
  end

  def labels_path_for(resource_parent)
    resource_parent.is_a?(Group) ? group_labels_path(resource_parent) : project_labels_path(resource_parent)
  end

  def rss_path_for(resource_parent)
    if resource_parent.is_a?(Group)
      group_work_items_path(resource_parent, format: :atom)
    else
      project_work_items_path(resource_parent, format: :atom)
    end
  end

  def calendar_path_for(resource_parent)
    if resource_parent.is_a?(Group)
      group_work_items_path(resource_parent, format: :ics)
    else
      project_work_items_path(resource_parent, format: :ics)
    end
  end
end
