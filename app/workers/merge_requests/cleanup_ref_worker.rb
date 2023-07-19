# frozen_string_literal: true

module MergeRequests
  class CleanupRefWorker
    include ApplicationWorker
    include Projects::RemoveRefs

    sidekiq_options retry: 3
    loggable_arguments 2
    feature_category :code_review_workflow

    idempotent!
    deduplicate :until_executed, if_deduplicated: :reschedule_once, ttl: 1.minute
    data_consistency :delayed

    urgency :low

    # Even though this worker is de-duplicated we need to acquire lock
    # on a project to avoid running many concurrent refs removals
    #
    # TODO: Once underlying fix is done we can remove `in_lock`
    #
    # Related to:
    # - https://gitlab.com/gitlab-org/gitaly/-/issues/5368
    # - https://gitlab.com/gitlab-org/gitaly/-/issues/5369
    def perform(merge_request_id, only)
      merge_request = MergeRequest.find_by_id(merge_request_id)
      return unless merge_request

      serialized_remove_refs(merge_request.target_project_id) do
        merge_request.cleanup_refs(only: only.to_sym)
      end
    end
  end
end
