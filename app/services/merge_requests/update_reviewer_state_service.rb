# frozen_string_literal: true

module MergeRequests
  class UpdateReviewerStateService < MergeRequests::BaseService
    def execute(merge_request, state)
      return error("Invalid permissions") unless can?(current_user, :update_merge_request, merge_request)

      reviewer = merge_request.find_reviewer(current_user)

      create_requested_changes(merge_request) if state == 'requested_changes'
      destroy_requested_changes(merge_request) if state == 'approved'
      create_reviewed_system_note(merge_request) if state == 'reviewed'

      if reviewer
        return error("Reviewer has approved") if reviewer.approved? && %w[requested_changes unapproved].exclude?(state)
        return error("Failed to update reviewer") unless reviewer.update(state: state)

        trigger_merge_request_reviewers_updated(merge_request)
        trigger_user_merge_request_updated(merge_request)
        invalidate_cache_counts(merge_request, users: merge_request.assignees)
        current_user.invalidate_merge_request_cache_counts

        return success if state != 'requested_changes'

        if merge_request.approved_by?(current_user) && !remove_approval(merge_request, current_user)
          return error("Failed to remove approval")
        end

        success
      else
        error("Reviewer not found")
      end
    end

    private

    def create_requested_changes(merge_request)
      merge_request.create_requested_changes(current_user)

      SystemNoteService.requested_changes(merge_request, current_user)

      trigger_merge_request_merge_status_updated(merge_request)
    end

    def destroy_requested_changes(merge_request)
      merge_request.destroy_requested_changes(current_user)
    end

    def create_reviewed_system_note(merge_request)
      return unless can_leave_reviewed_system_note

      SystemNoteService.reviewed(merge_request, current_user)
    end

    def can_leave_reviewed_system_note
      return true unless current_user.respond_to?(:user_type)

      current_user.user_type != 'duo_code_review_bot'
    end
  end
end
