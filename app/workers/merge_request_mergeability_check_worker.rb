# frozen_string_literal: true

class MergeRequestMergeabilityCheckWorker
  include ApplicationWorker

  sidekiq_options retry: 3

  feature_category :code_review
  idempotent!

  def perform(merge_request_id)
    merge_request = MergeRequest.find_by_id(merge_request_id)

    unless merge_request
      logger.error("Failed to find merge request with ID: #{merge_request_id}")
      return
    end

    result =
      ::MergeRequests::MergeabilityCheckService
        .new(merge_request)
        .execute(recheck: false, retry_lease: false)

    logger.error("Failed to check mergeability of merge request (#{merge_request_id}): #{result.message}") if result.error?
  end
end
