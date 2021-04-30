# frozen_string_literal: true

class UpdateHeadPipelineForMergeRequestWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include PipelineQueue

  queue_namespace :pipeline_processing
  feature_category :continuous_integration
  urgency :high
  worker_resource_boundary :cpu

  idempotent!

  def perform(merge_request_id)
    MergeRequest.find_by_id(merge_request_id).try do |merge_request|
      merge_request.update_head_pipeline
    end
  end
end
