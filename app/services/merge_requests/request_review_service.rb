# frozen_string_literal: true

module MergeRequests
  class RequestReviewService < MergeRequests::BaseService
    def execute(merge_request, user)
      return error("Invalid permissions") unless can?(current_user, :update_merge_request, merge_request)

      with_valid_reviewer(merge_request, user) do |reviewer|
        # Capture old state for webhook (re_requested will be false for historical state)
        old_reviewers_hook_attrs = merge_request.reviewers_hook_attrs

        has_unapproved = remove_approval(merge_request, user).present?

        break error("Failed to update reviewer") unless reviewer.update(state: :unreviewed)

        notify_reviewer(merge_request, user)
        trigger_merge_request_merge_status_updated(merge_request)
        trigger_merge_request_reviewers_updated(merge_request)
        trigger_merge_request_approval_state_updated(merge_request)
        trigger_user_merge_request_updated(merge_request)
        create_system_note(merge_request, user, has_unapproved)

        # Trigger webhook with old association data to show state change
        old_associations = {
          reviewers_hook_attrs: old_reviewers_hook_attrs,
          re_requested_reviewer_id: reviewer.user_id
        }
        execute_hooks(merge_request, 'update', old_associations: old_associations)

        user.invalidate_merge_request_cache_counts
        current_user.invalidate_merge_request_cache_counts
        request_duo_code_review(merge_request) if user == duo_code_review_bot
        execute_flow_triggers(merge_request, [user], :assign_reviewer)

        success
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

    def with_valid_reviewer(merge_request, user)
      reviewer = merge_request.find_reviewer(user)

      if reviewer
        yield reviewer
      else
        error("Reviewer not found")
      end
    end
  end
end

MergeRequests::RequestReviewService.prepend_mod
