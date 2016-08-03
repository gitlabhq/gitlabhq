# Description: https://coderwall.com/p/heed_q/rails-routing-and-namespaced-models
#
# This allows us to use CI ActiveRecord objects in all routes and use it:
# - [project.namespace, project, build]
#
# instead of:
# - namespace_project_build_path(project.namespace, project, build)
#
# Without that, Ci:: namespace is used for resolving routes:
# - namespace_project_ci_build_path(project.namespace, project, build)

module Ci
  def self.use_relative_model_naming?
    true
  end
end
