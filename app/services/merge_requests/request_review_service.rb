# frozen_string_literal: true

module MergeRequests
  class RequestReviewService < MergeRequests::BaseService
    def execute(merge_request, user)
      return error("Invalid permissions") unless can?(current_user, :update_merge_request, merge_request)

      reviewer = merge_request.find_reviewer(user)

      if reviewer
        return error("Failed to update reviewer") unless reviewer.update(state: :unreviewed)

        notify_reviewer(merge_request, user)

        success
      else
        error("Reviewer not found")
      end
    end

    private

    def notify_reviewer(merge_request, reviewer)
      notification_service.async.review_requested_of_merge_request(merge_request, current_user, reviewer)
      todo_service.create_request_review_todo(merge_request, current_user, reviewer)
    end
  end
end
