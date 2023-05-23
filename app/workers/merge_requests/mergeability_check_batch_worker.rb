# frozen_string_literal: true

module MergeRequests
  class MergeabilityCheckBatchWorker
    include ApplicationWorker

    data_consistency :sticky

    sidekiq_options retry: 3

    feature_category :code_review_workflow
    idempotent!

    def logger
      @logger ||= Sidekiq.logger
    end

    def perform(merge_request_ids)
      merge_requests = MergeRequest.id_in(merge_request_ids)

      merge_requests.each do |merge_request|
        result = merge_request.check_mergeability

        next unless result&.error?

        logger.error(
          worker: self.class.name,
          message: "Failed to check mergeability of merge request: #{result.message}",
          merge_request_id: merge_request.id
        )
      end
    end
  end
end
