# frozen_string_literal: true

module Ci
  class AbortPipelinesService
    ABORT_PIPELINE_BATCHING_LIMIT = 100_000
    PipelinesAbortLimitExceededError = Class.new(StandardError)

    # NOTE: This call fails pipelines in bulk without running callbacks.
    # Only for pipeline abandonment scenarios (examples: project delete)
    def execute(pipelines, failure_reason)
      batch_size = 100
      processed_count = 0

      loop do
        processed_count += 1
        if processed_count > ABORT_PIPELINE_BATCHING_LIMIT
          raise PipelinesAbortLimitExceededError, "Exceeded the maximum batching limit to abort pipelines"
        end

        # Limit to 100 pipelines per batch - marking the cancelable pipelines as failed in the loop removes them from
        # subsequent queries which is more efficient than each_batch.
        pipeline_ids = pipelines.cancelable.limit(batch_size).pluck_primary_key
        now = Time.current

        basic_attributes = { status: :failed }
        all_attributes = basic_attributes.merge(failure_reason: failure_reason, finished_at: now)

        bulk_fail_for(Ci::Stage, pipeline_ids, basic_attributes)
        bulk_fail_for(CommitStatus, pipeline_ids, all_attributes)

        update_size = ::Ci::Pipeline.id_in(pipeline_ids).update_all(all_attributes)
        break if update_size < batch_size
      end

      ServiceResponse.success(message: 'Pipelines stopped')
    end

    private

    def bulk_fail_for(klass, pipelines, attributes)
      klass.in_pipelines(pipelines)
        .cancelable
        .in_batches(of: 150) # rubocop:disable Cop/InBatches
        .update_all(attributes)
    end
  end
end
