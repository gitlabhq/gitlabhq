module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Create < Chain::Base
          include Chain::Helpers

          # rubocop: disable CodeReuse/ActiveRecord
          def perform!
            ::Ci::Pipeline.transaction do
              pipeline.save!

              ##
              # Create environments before the pipeline starts.
              #
              pipeline.builds.each do |build|
                if build.has_environment?
                  environment = project.environments.find_or_create_by(
                    name: build.expanded_environment_name
                  )

                  project.deployments.create(
                    environment: environment,
                    ref: build.ref,
                    tag: build.tag,
                    sha: build.sha,
                    user: build.user,
                    deployable: build,
                    on_stop: on_stop(build))
                end
              end
            end
          rescue ActiveRecord::RecordInvalid => e
            error("Failed to persist the pipeline: #{e}")
          end
          # rubocop: enable CodeReuse/ActiveRecord

          def break?
            !pipeline.persisted?
          end

          def environment_options(build)
            build.options&.dig(:environment) || {}
          end
  
          def on_stop(build)
            environment_options(build).fetch(:on_stop, nil)
          end
        end
      end
    end
  end
end
