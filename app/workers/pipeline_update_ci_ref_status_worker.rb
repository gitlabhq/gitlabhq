# frozen_string_literal: true

class PipelineUpdateCiRefStatusWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include PipelineQueue

  latency_sensitive_worker!
  worker_resource_boundary :cpu

  def perform(pipeline_id)
    pipeline = Ci::Pipeline.find_by_id(pipeline_id)

    return unless pipeline

    Ci::UpdateCiRefStatusService.new(pipeline).call
  end
end
