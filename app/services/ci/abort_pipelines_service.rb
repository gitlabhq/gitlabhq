# frozen_string_literal: true

module Ci
  class AbortPipelinesService
    # Danger: Cancels in bulk without callbacks
    # Only for pipeline abandonment scenarios (examples: project delete, user block)
    def execute(pipelines)
      @time = Time.current

      bulk_abort!(pipelines.cancelable, { status: :canceled })

      ServiceResponse.success(message: 'Pipelines canceled')
    end

    private

    def bulk_abort!(pipelines, attributes)
      pipelines.each_batch(of: 100) do |pipeline_batch|
        update_status_for(Ci::Stage, pipeline_batch, attributes)
        update_status_for(CommitStatus, pipeline_batch, attributes.merge(finished_at: @time))

        pipeline_batch.update_all(attributes.merge(finished_at: @time))
      end
    end

    def update_status_for(klass, pipelines, attributes)
      klass.in_pipelines(pipelines)
        .cancelable
        .in_batches(of: 150) # rubocop:disable Cop/InBatches
        .update_all(attributes)
    end
  end
end
