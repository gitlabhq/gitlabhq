# frozen_string_literal: true

module Ci
  class AbortPipelinesService
    # NOTE: This call fails pipelines in bulk without running callbacks.
    # Only for pipeline abandonment scenarios (examples: project delete)
    def execute(pipelines, failure_reason)
      pipelines.cancelable.each_batch(of: 100) do |pipeline_batch|
        now = Time.current

        basic_attributes = { status: :failed }
        all_attributes = basic_attributes.merge(failure_reason: failure_reason, finished_at: now)

        bulk_fail_for(Ci::Stage, pipeline_batch, basic_attributes)
        bulk_fail_for(CommitStatus, pipeline_batch, all_attributes)

        pipeline_batch.update_all(all_attributes)
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
