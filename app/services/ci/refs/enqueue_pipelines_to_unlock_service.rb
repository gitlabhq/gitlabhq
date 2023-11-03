# frozen_string_literal: true

module Ci
  module Refs
    class EnqueuePipelinesToUnlockService
      include BaseServiceUtility

      BATCH_SIZE = 50
      ENQUEUE_INTERVAL_SECONDS = 0.1
      EXCLUDED_IDS_LIMIT = 1000

      def execute(ci_ref, before_pipeline: nil)
        total_new_entries = 0

        pipelines_scope(ci_ref, before_pipeline).each_batch(of: BATCH_SIZE) do |batch|
          pipeline_ids = batch.pluck(:id) # rubocop: disable CodeReuse/ActiveRecord
          total_added = Ci::UnlockPipelineRequest.enqueue(pipeline_ids)
          total_new_entries += total_added

          # Take a little rest to avoid overloading Redis
          sleep ENQUEUE_INTERVAL_SECONDS
        end

        success(
          total_pending_entries: Ci::UnlockPipelineRequest.total_pending,
          total_new_entries: total_new_entries
        )
      end

      private

      def pipelines_scope(ci_ref, before_pipeline)
        scope = ci_ref.pipelines.artifacts_locked

        if before_pipeline
          # We use `same_family_pipeline_ids.map(&:id)` to force run the query and
          # specifically pass the array of IDs to the NOT IN condition. If not, we would
          # end up running the subquery for same_family_pipeline_ids on each batch instead.
          excluded_ids = before_pipeline.same_family_pipeline_ids.map(&:id)
          scope = scope.created_before_id(before_pipeline.id)

          # When unlocking previous pipelines, we still want to keep the
          # last successful CI source pipeline locked.
          # If before_pipeline is not provided, like in the case of deleting a ref,
          # we want to unlock all pipelines instead.
          ci_ref.last_successful_ci_source_pipeline.try do |pipeline|
            excluded_ids.concat(pipeline.same_family_pipeline_ids.map(&:id))
          end

          # We add a limit to the excluded IDs just to be safe and avoid any
          # arity issues with the NOT IN query.
          scope = scope.where.not(id: excluded_ids.take(EXCLUDED_IDS_LIMIT)) # rubocop: disable CodeReuse/ActiveRecord
        end

        scope
      end
    end
  end
end
