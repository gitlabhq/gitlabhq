# frozen_string_literal: true

class PipelineUpdateWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_processing
  urgency :high

  idempotent!

  def perform(pipeline_id)
    Ci::Pipeline.find_by_id(pipeline_id)&.update_legacy_status
  end
end
