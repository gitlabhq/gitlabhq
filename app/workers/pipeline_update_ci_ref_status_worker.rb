# frozen_string_literal: true

# NOTE: This class is unused and to be removed in 13.1~
class PipelineUpdateCiRefStatusWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include PipelineQueue

  urgency :high
  worker_resource_boundary :cpu

  def perform(pipeline_id)
    pipeline = Ci::Pipeline.find_by_id(pipeline_id)

    return unless pipeline

    Ci::UpdateCiRefStatusService.new(pipeline).call
  end
end
