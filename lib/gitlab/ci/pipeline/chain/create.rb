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
            if pipeline.builds.where(stage_id: nil).any?
              invalid_builds_counter.increment(node: hostname)
            end
          end

          def break?
            !pipeline.persisted?
          end

          private

          def invalid_builds_counter
            @counter ||= Gitlab::Metrics
              .counter(:gitlab_ci_invalid_builds_total,
                       'Invalid builds without stage assigned counter')
          end

          def hostname
            @hostname ||= Socket.gethostname
          end
        end
      end
    end
  end
end
