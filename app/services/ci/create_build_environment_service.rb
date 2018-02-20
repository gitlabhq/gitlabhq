module Ci
  class CreateBuildEnvironmentService < BaseService
    def execute(build)
      environment_name = build.expanded_environment_name
      project.environments.find_or_create_by!(name: environment_name)
    end
  end
end
