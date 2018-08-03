module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Create < Chain::Base
          include Chain::Helpers

          def perform!
            ::Ci::Pipeline.transaction do
              pipeline.save!

              ##
              # Create environments before the pipeline starts.
              #
              pipeline.builds.each do |build|
                create_environment_objects(build) if build.has_environment?
              end
            end
          rescue ActiveRecord::RecordInvalid => e
            error("Failed to persist the pipeline: #{e}")
          end

          def break?
            !pipeline.persisted?
          end

          private

          def create_environment_objects(build)
            environment = project.environments.find_or_create_by(
              name: build.expanded_environment_name
            )

            build.create_build_environment_deployment(environment: environment)
          end
        end
      end
    end
  end
end
