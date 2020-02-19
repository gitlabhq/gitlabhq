# frozen_string_literal: true

class UpdateHeadPipelineForMergeRequestWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_processing
  feature_category :continuous_integration
  latency_sensitive_worker!
  worker_resource_boundary :cpu

  def perform(merge_request_id)
    MergeRequest.find_by_id(merge_request_id).try do |merge_request|
      merge_request.update_head_pipeline
    end
  end
end
