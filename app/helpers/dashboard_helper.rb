module DashboardHelper
  def assigned_issues_dashboard_path
    issues_dashboard_path(assignee_id: current_user.id)
  end

  def assigned_mrs_dashboard_path
    merge_requests_dashboard_path(assignee_id: current_user.id)
  end
end
