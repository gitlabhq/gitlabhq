# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class CancelPendingPipelines < Chain::Base
          include Chain::Helpers

          def perform!
            return unless project.auto_cancel_pending_pipelines?

            Gitlab::OptimisticLocking.retry_lock(auto_cancelable_pipelines, name: 'cancel_pending_pipelines') do |cancelables|
              cancelables.find_each do |cancelable|
                cancelable.auto_cancel_running(pipeline)
              end
            end
          end

          def break?
            false
          end

          private

          # rubocop: disable CodeReuse/ActiveRecord
          def auto_cancelable_pipelines
            project.all_pipelines.ci_and_parent_sources
              .where(ref: pipeline.ref)
              .where.not(id: pipeline.same_family_pipeline_ids)
              .where.not(sha: project.commit(pipeline.ref).try(:id))
              .alive_or_scheduled
              .with_only_interruptible_builds
          end
          # rubocop: enable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
