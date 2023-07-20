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

    def perform(merge_request_ids, user_id)
      merge_requests = MergeRequest.id_in(merge_request_ids)
      user = User.find_by_id(user_id)

      merge_requests.each do |merge_request|
        # Skip projects that user doesn't have update_merge_request access
        next if merge_status_recheck_not_allowed?(merge_request, user)

        merge_request.mark_as_checking

        result = merge_request.check_mergeability

        next unless result&.error?

        logger.error(
          worker: self.class.name,
          message: "Failed to check mergeability of merge request: #{result.message}",
          merge_request_id: merge_request.id
        )
      end
    end

    private

    def merge_status_recheck_not_allowed?(merge_request, user)
      !Ability.allowed?(user, :update_merge_request, merge_request.project)
    end
  end
end
