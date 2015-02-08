module DashboardHelper
  def projects_dashboard_filter_path(options={})
    exist_opts = {
      sort: params[:sort],
      scope: params[:scope],
      group: params[:group],
      tag: params[:tag],
      visibility_level: params[:visibility_level],
    }

    options = exist_opts.merge(options)

    path = request.path
    path << "?#{options.to_param}"
    path
  end

  def assigned_issues_dashboard_path
    issues_dashboard_path(assignee_id: current_user.id)
  end

  def assigned_mrs_dashboard_path
    merge_requests_dashboard_path(assignee_id: current_user.id)
  end
end
