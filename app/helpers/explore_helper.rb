module ExploreHelper
  def explore_projects_filter_path(options={})
    exist_opts = {
      sort: params[:sort],
      scope: params[:scope],
      group: params[:group],
      tag: params[:tag],
      visibility_level: params[:visibility_level],
    }

    options = exist_opts.merge(options)

    path = if explore_controller?
             explore_projects_path
           elsif current_action?(:starred)
             starred_dashboard_projects_path
           else
             dashboard_projects_path
           end

    path << "?#{options.to_param}"
    path
  end

  def explore_controller?
    controller.class.name.split("::").first == "Explore"
  end
end
