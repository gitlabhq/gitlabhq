# frozen_string_literal: true

module MergeRequests
  class UpdateReviewerStateService < MergeRequests::BaseService
    def execute(merge_request, state)
      return error("Invalid permissions") unless can?(current_user, :update_merge_request, merge_request)

      reviewer = merge_request.find_reviewer(current_user)

      if reviewer
        return error("Failed to update reviewer") unless reviewer.update(state: state)

        trigger_merge_request_reviewers_updated(merge_request)

        return success if state != 'requested_changes'

        if merge_request.approved_by?(current_user) && !remove_approval(merge_request, current_user)
          return error("Failed to remove approval")
        end

        success
      else
        error("Reviewer not found")
      end
    end
  end
end
