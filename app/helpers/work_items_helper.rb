# frozen_string_literal: true

module WorkItemsHelper
  def work_items_index_data(project)
    {
      full_path: project.full_path,
      issues_list_path: project_issues_path(project)
    }
  end
end
