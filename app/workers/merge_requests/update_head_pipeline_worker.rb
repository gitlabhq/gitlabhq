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
      pipeline = if event.data[:partition_id]
                   Ci::Pipeline.in_partition(event.data[:partition_id]).find_by_id(event.data[:pipeline_id])
                 else
                   # TODO: In the next milestone, make partition_id required in event data, then remove this code path.
                   # See https://gitlab.com/gitlab-org/gitlab/-/issues/578790
                   Ci::Pipeline.find_by_id(event.data[:pipeline_id])
                 end

      return unless pipeline

      pipeline.all_merge_requests.opened.each do |merge_request|
        merge_request.update_head_pipeline
      end
    end
  end
end
