# frozen_string_literal: true

module Ci
  class AbortPipelinesService
    # Danger: Cancels in bulk without callbacks
    # Only for pipeline abandonment scenarios (examples: project delete, user block)
    def execute(pipelines)
      bulk_abort!(pipelines.cancelable, status: :canceled)

      ServiceResponse.success(message: 'Pipelines canceled')
    end

    private

    def bulk_abort!(pipelines, status:)
      pipelines.each_batch(of: 100) do |pipeline_batch|
        update_status_for(Ci::Stage, pipeline_batch, status)
        update_status_for(CommitStatus, pipeline_batch, status)
        pipeline_batch.update_all(status: status, finished_at: Time.current)
      end
    end

    def update_status_for(klass, pipelines, status)
      klass.in_pipelines(pipelines)
        .cancelable
        .in_batches(of: 150) # rubocop:disable Cop/InBatches
        .update_all(status: status)
    end
  end
end
