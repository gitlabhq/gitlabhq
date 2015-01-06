module DashboardHelper
  def entities_per_project(project, entity)
    case entity.to_sym
    when :issue
      @issues.where(project_id: project.id)
    when :merge_request
      @merge_requests.where(target_project_id: project.id)
    else
      []
    end.count
  end

  def projects_dashboard_filter_path(options = {})
    merge_params_path(options, [:sort, :scope, :group])
  end

  def assigned_issues_dashboard_path
    issues_dashboard_path(assignee_id: current_user.id)
  end

  def assigned_mrs_dashboard_path
    merge_requests_dashboard_path(assignee_id: current_user.id)
  end
end
