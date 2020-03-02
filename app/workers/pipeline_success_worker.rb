# frozen_string_literal: true

class PipelineSuccessWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_processing
  urgency :high

  def perform(pipeline_id)
    # no-op
  end
end
