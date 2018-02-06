module Ci
  class CreatePipelineStagesService < BaseService
    def execute(pipeline)
      pipeline.stage_seeds.each do |seed|
        seed.user = current_user

        seed.create! do |build|
          ##
          # Create the environment before the build starts. This sets its slug and
          # makes it available as an environment variable
          #
          if build.has_environment?
            environment_name = build.expanded_environment_name
            project.environments.find_or_create_by(name: environment_name)
          end
        end
      end
    end
  end
end
