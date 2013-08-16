module DashboardHelper
  def filter_path(entity, options={})
    exist_opts = {
      status: params[:status],
      project_id: params[:project_id],
    }

    options = exist_opts.merge(options)

    path = request.path
    path << "?#{options.to_param}"
    path
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

    items.cared(current_user).count
  end
end
