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
                build.ensure_environment_deployment&.save!
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
