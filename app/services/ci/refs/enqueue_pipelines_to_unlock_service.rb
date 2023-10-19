# frozen_string_literal: true

module Ci
  module Refs
    class EnqueuePipelinesToUnlockService
      include BaseServiceUtility

      BATCH_SIZE = 50
      ENQUEUE_INTERVAL_SECONDS = 0.1

      def execute(ci_ref, before_pipeline: nil)
        pipelines_scope = ci_ref.pipelines.artifacts_locked
        pipelines_scope = pipelines_scope.before_pipeline(before_pipeline) if before_pipeline
        total_new_entries = 0

        pipelines_scope.each_batch(of: BATCH_SIZE) do |batch|
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
    end
  end
end
