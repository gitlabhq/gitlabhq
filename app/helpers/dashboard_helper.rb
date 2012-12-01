module DashboardHelper
  def dashboard_filter_path(entity, options={})
    exist_opts = {
      status: params[:status],
      project_id: params[:project_id],
    }

    options = exist_opts.merge(options)

    case entity
    when 'issue' then
      dashboard_issues_path(options)
    when 'merge_request'
      dashboard_merge_requests_path(options)
    end
  end

  def entities_per_project project, entity
    items = project.items_for(entity)

    items = case params[:status]
            when 'closed'
              items.closed
            when 'all'
              items
            else
              items.opened
            end

    items.where(assignee_id: current_user.id).count
  end
end
