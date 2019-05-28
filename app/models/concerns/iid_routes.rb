# frozen_string_literal: true

module IidRoutes
  ##
  # This automagically enforces all related routes to use `iid` instead of `id`
  # If you want to use `iid` for some routes and `id` for other routes, this module should not to be included,
  # instead you should define `iid` or `id` explicitly at each route generators. e.g. pipeline_path(project.id, pipeline.iid)
  def to_param
    iid.to_s
  end
end
