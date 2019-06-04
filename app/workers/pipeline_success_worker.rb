# frozen_string_literal: true

class PipelineSuccessWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_processing

  def perform(pipeline_id)
    # no-op
  end
end
