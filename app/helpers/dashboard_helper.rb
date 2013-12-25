module DashboardHelper
  def filter_path(entity, options={})
    exist_opts = {
      status: params[:status],
      scope: params[:scope],
      project_id: params[:project_id],
    }

    options = exist_opts.merge(options)

    path = request.path
    path << "?#{options.to_param}"
    path
  end

  def entities_per_project(project, entity)
    case entity.to_sym
    when :issue then @issues.where(project_id: project.id)
    when :merge_request then @merge_requests.where(target_project_id: project.id)
    else
      []
    end.count
  end
end
