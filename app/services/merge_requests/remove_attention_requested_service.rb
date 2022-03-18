# frozen_string_literal: true

module MergeRequests
  class RemoveAttentionRequestedService < MergeRequests::BaseService
    attr_accessor :merge_request

    def initialize(project:, current_user:, merge_request:)
      super(project: project, current_user: current_user)

      @merge_request = merge_request
    end

    def execute
      return error("Invalid permissions") unless can?(current_user, :update_merge_request, merge_request)

      if reviewer || assignee
        update_state(reviewer)
        update_state(assignee)

        current_user.invalidate_attention_requested_count

        success
      else
        error("User is not a reviewer or assignee of the merge request")
      end
    end

    private

    def assignee
      merge_request.find_assignee(current_user)
    end

    def reviewer
      merge_request.find_reviewer(current_user)
    end

    def update_state(reviewer_or_assignee)
      reviewer_or_assignee&.update(state: :reviewed)
    end
  end
end
