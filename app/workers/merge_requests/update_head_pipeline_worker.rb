# frozen_string_literal: true

module MergeRequests
  class UpdateHeadPipelineWorker
    include Gitlab::EventStore::Subscriber

    feature_category :code_review_workflow
    urgency :high
    worker_resource_boundary :cpu
    data_consistency :always

    idempotent!

    def handle_event(event)
      pipeline = Ci::Pipeline.in_partition(event.data[:partition_id]).find_by_id(event.data[:pipeline_id])
      return unless pipeline

      pipeline.all_merge_requests.opened.each do |merge_request|
        merge_request.update_head_pipeline
      end
    end
  end
end
