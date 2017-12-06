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
            end
          rescue ActiveRecord::RecordInvalid => e
            error("Failed to persist the pipeline: #{e}")
          ensure
            pipeline.builds.find_each do |build|
              next if build.stage_id.present?

              invalid_builds_counter.increment(node: hostname)
            end
          end

          def break?
            !pipeline.persisted?
          end

          private

          def invalid_builds_counter
            @counter ||= Gitlab::Metrics
              .counter(:invalid_builds_counter, 'Invalid builds counter')
          end

          def hostname
            @hostname ||= Socket.gethostname
          end
        end
      end
    end
  end
end
