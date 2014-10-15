module DashboardHelper
  def filter_path(entity, options={})
    exist_opts = {
      state: params[:state],
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

  def projects_dashboard_filter_path(options={})
    exist_opts = {
      sort: params[:sort],
      scope: params[:scope],
      group: params[:group],
    }

    options = exist_opts.merge(options)

    path = request.path
    path << "?#{options.to_param}"
    path
  end

  def assigned_entities_count(current_user, entity, scope = nil)
    items = current_user.send('assigned_' + entity.pluralize)
    get_count(items, scope)
  end

  def authored_entities_count(current_user, entity, scope = nil)
    items = current_user.send(entity.pluralize)
    get_count(items, scope)
  end

  def authorized_entities_count(current_user, entity, scope = nil)
    items = entity.classify.constantize
    get_count(items, scope, true, current_user)
  end

  protected

  def get_count(items, scope, get_authorized = false, current_user = nil)
    items = items.opened
    if scope.kind_of?(Group)
      items = items.of_group(scope)
    elsif scope.kind_of?(Project)
      items = items.of_projects(scope)
    elsif get_authorized
      items = items.of_projects(current_user.authorized_projects)
    end
    items.count
  end
end
