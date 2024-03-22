# frozen_string_literal: true

module WorkItemsHelper
  def work_items_show_data(resource_parent)
    group = resource_parent.is_a?(Group) ? resource_parent : resource_parent.group

    {
      full_path: resource_parent.full_path,
      issues_list_path:
        resource_parent.is_a?(Group) ? issues_group_path(resource_parent) : project_issues_path(resource_parent),
      register_path: new_user_registration_path(redirect_to_referer: 'yes'),
      sign_in_path: new_session_path(:user, redirect_to_referer: 'yes'),
      new_comment_template_paths: new_comment_template_paths(group).to_json,
      report_abuse_path: add_category_abuse_reports_path
    }
  end

  def work_items_list_data(group, current_user)
    {
      full_path: group.full_path,
      initial_sort: current_user&.user_preference&.issues_sort,
      is_signed_in: current_user.present?.to_s
    }
  end
end
