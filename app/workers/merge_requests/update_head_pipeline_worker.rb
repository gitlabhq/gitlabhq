# frozen_string_literal: true

module MergeRequests
  class UpdateHeadPipelineWorker
    include Gitlab::EventStore::Subscriber

    feature_category :code_review
    urgency :high
    worker_resource_boundary :cpu
    data_consistency :always

    idempotent!

    def handle_event(event)
      Ci::Pipeline.find_by_id(event.data[:pipeline_id]).try do |pipeline|
        pipeline.all_merge_requests.opened.each do |merge_request|
          UpdateHeadPipelineForMergeRequestWorker.perform_async(merge_request.id)
        end
      end
    end
  end
end
