# frozen_string_literal: true

module MergeRequests
  # Warms the merge request diffs highlight/stats cache off the critical path of
  # MergeRequests::AfterCreateService. The cache is display-only and is not
  # required for the merge request to be marked as prepared, so writing it can
  # be deferred to a worker instead of blocking new-MR preparation.
  class WriteDiffsCacheWorker
    include ApplicationWorker

    data_consistency :sticky

    idempotent!
    deduplicate :until_executed

    feature_category :code_review_workflow
    urgency :low
    worker_resource_boundary :cpu

    defer_on_database_health_signal :gitlab_main

    def perform(merge_request_id)
      merge_request = MergeRequest.find_by_id(merge_request_id)
      return unless merge_request

      merge_request.diffs(include_stats: false).write_cache
    end
  end
end
