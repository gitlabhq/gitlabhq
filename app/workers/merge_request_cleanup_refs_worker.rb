# frozen_string_literal: true

class MergeRequestCleanupRefsWorker
  include ApplicationWorker

  sidekiq_options retry: 3

  feature_category :code_review
  tags :exclude_from_kubernetes
  idempotent!

  def perform(merge_request_id)
    return unless Feature.enabled?(:merge_request_refs_cleanup, default_enabled: false)

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
