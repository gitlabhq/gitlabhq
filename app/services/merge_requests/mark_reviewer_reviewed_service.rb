# frozen_string_literal: true

module MergeRequests
  class MarkReviewerReviewedService < MergeRequests::BaseService
    def execute(merge_request)
      return error("Invalid permissions") unless can?(current_user, :update_merge_request, merge_request)

      reviewer = merge_request.find_reviewer(current_user)

      if reviewer
        return error("Failed to update reviewer") unless reviewer.update(state: :reviewed)

        success
      else
        error("Reviewer not found")
      end
    end
  end
end
