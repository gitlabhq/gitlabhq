# frozen_string_literal: true

module WorkItemsHelper
  def work_items_show_data(resource_parent, current_user)
    group = resource_parent.is_a?(Group) ? resource_parent : resource_parent.group

    {
      autocomplete_award_emojis_path: autocomplete_award_emojis_path,
      can_admin_label: can?(current_user, :admin_label, resource_parent).to_s,
      full_path: resource_parent.full_path,
      group_path: group&.full_path,
      issues_list_path:
        resource_parent.is_a?(Group) ? issues_group_path(resource_parent) : project_issues_path(resource_parent),
      labels_manage_path:
        resource_parent.is_a?(Group) ? group_labels_path(resource_parent) : project_labels_path(resource_parent),
      register_path: new_user_registration_path(redirect_to_referer: 'yes'),
      sign_in_path: new_session_path(:user, redirect_to_referer: 'yes'),
      new_comment_template_paths: new_comment_template_paths(group).to_json,
      report_abuse_path: add_category_abuse_reports_path,
      default_branch: resource_parent.is_a?(Project) ? resource_parent.default_branch_or_main : nil,
      initial_sort: current_user&.user_preference&.issues_sort,
      is_signed_in: current_user.present?.to_s,
      show_new_issue_link: can?(current_user, :create_work_item, group).to_s,
      can_create_projects: can?(current_user, :create_projects, group).to_s,
      new_project_path: new_project_path(namespace_id: group&.id),
      group_id: group&.id
    }
  end

  # overriden in EE
  def add_work_item_show_breadcrumb(resource_parent, _iid)
    path = resource_parent.is_a?(Group) ? issues_group_path(resource_parent) : project_issues_path(resource_parent)

    add_to_breadcrumbs(_('Issues'), path)
  end

  def work_items_list_data(group, current_user)
    {
      autocomplete_award_emojis_path: autocomplete_award_emojis_path,
      full_path: group.full_path,
      initial_sort: current_user&.user_preference&.issues_sort,
      is_signed_in: current_user.present?.to_s,
      show_new_issue_link: can?(current_user, :create_work_item, group).to_s,
      issues_list_path: issues_group_path(group),
      report_abuse_path: add_category_abuse_reports_path,
      labels_manage_path: group_labels_path(group),
      can_admin_label: can?(current_user, :admin_label, group).to_s
    }
  end
end
