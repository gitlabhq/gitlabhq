# frozen_string_literal: true

module MergeRequests
  class RequestReviewService < MergeRequests::BaseService
    def execute(merge_request, user)
      return error("Invalid permissions") unless can?(current_user, :update_merge_request, merge_request)

      reviewer = merge_request.find_reviewer(user)

      if reviewer
        has_unapproved = remove_approval(merge_request, user).present?

        return error("Failed to update reviewer") unless reviewer.update(state: :unreviewed)

        notify_reviewer(merge_request, user)
        trigger_merge_request_merge_status_updated(merge_request)
        trigger_merge_request_reviewers_updated(merge_request)
        trigger_merge_request_approval_state_updated(merge_request)
        trigger_user_merge_request_updated(merge_request)
        create_system_note(merge_request, user, has_unapproved)

        user.invalidate_merge_request_cache_counts if user.merge_request_dashboard_enabled?
        current_user.invalidate_merge_request_cache_counts if current_user.merge_request_dashboard_enabled?
        request_duo_code_review(merge_request) if user == ::Users::Internal.duo_code_review_bot

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

    def create_system_note(merge_request, user, has_unapproved)
      ::SystemNoteService.request_review(merge_request, merge_request.project, current_user, user, has_unapproved)
    end
  end
end
