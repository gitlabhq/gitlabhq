module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Create < Chain::Base
          include Chain::Helpers

          def perform!
            ::Ci::Pipeline.transaction do
              pipeline.save!

              @command.seeds_block&.call(pipeline)

              ::Ci::CreatePipelineStagesService
                .new(project, current_user)
                .execute(pipeline)

              # TODO populate environments with find_or_initialize_by in the chain too.

              ##
              # Create the environment before the build starts. This sets its slug and
              # makes it available as an environment variable
              #
              pipeline.builds.each do |build|
                if build.has_environment?
                  environment_name = build.expanded_environment_name
                  project.environments.find_or_create_by(name: environment_name)
                end
              end
            end
          rescue ActiveRecord::RecordInvalid => e
            error("Failed to persist the pipeline: #{e}")
          end

          def break?
            !pipeline.persisted?
          end
        end
      end
    end
  end
end
