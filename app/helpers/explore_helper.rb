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

    path = explore_projects_path
    path << "?#{options.to_param}"
    path
  end
end
