# frozen_string_literal: true

module MergeRequests
  class EnsurePreparedWorker
    include ApplicationWorker
    include CronjobQueue

    feature_category :code_review_workflow
    idempotent!
    deduplicate :until_executed
    data_consistency :sticky

    JOBS_PER_10_SECONDS = 5

    def perform
      return unless Feature.enabled?(:ensure_merge_requests_prepared)

      scope = MergeRequest.recently_unprepared

      iterator = Gitlab::Pagination::Keyset::Iterator.new(scope: scope)

      index = 0
      iterator.each_batch(of: JOBS_PER_10_SECONDS) do |merge_requests|
        index += 1

        NewMergeRequestWorker.bulk_perform_in_with_contexts(index * 10.seconds,
          merge_requests,
          arguments_proc: ->(merge_request) { [merge_request.id, merge_request.author_id] },
          context_proc: ->(merge_request) { { project: merge_request.project } }
        )
      end
    end
  end
end
