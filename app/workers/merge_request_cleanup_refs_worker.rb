# frozen_string_literal: true

class MergeRequestCleanupRefsWorker
  include ApplicationWorker

  feature_category :source_code_management
  idempotent!

  def perform(merge_request_id)
    merge_request = MergeRequest.find_by_id(merge_request_id)

    unless merge_request
      logger.error("Failed to find merge request with ID: #{merge_request_id}")
      return
    end

    result = ::MergeRequests::CleanupRefsService.new(merge_request).execute

    return if result[:status] == :success

    logger.error("Failed cleanup refs of merge request (#{merge_request_id}): #{result[:message]}")
  end
end
