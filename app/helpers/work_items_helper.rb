# frozen_string_literal: true

module WorkItemsHelper
  def work_items_index_data(project)
    {
      full_path: project.full_path,
      issues_list_path: project_issues_path(project),
      register_path: new_user_registration_path(redirect_to_referer: 'yes'),
      sign_in_path: new_session_path(:user, redirect_to_referer: 'yes')
    }
  end
end
