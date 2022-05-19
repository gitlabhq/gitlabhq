# frozen_string_literal: true

module MergeRequests
  class RemoveAttentionRequestedService < MergeRequests::BaseService
    attr_accessor :merge_request, :user

    def initialize(project:, current_user:, merge_request:, user:)
      super(project: project, current_user: current_user)

      @merge_request = merge_request
      @user = user
    end

    def execute
      return error("Invalid permissions") unless can?(current_user, :update_merge_request, merge_request)

      if reviewer || assignee
        return success if reviewer&.reviewed? || assignee&.reviewed?

        update_state(reviewer)
        update_state(assignee)

        user.invalidate_attention_requested_count
        create_remove_attention_request_note

        success
      else
        error("User is not a reviewer or assignee of the merge request")
      end
    end

    private

    def assignee
      @assignee ||= merge_request.find_assignee(user)
    end

    def reviewer
      @reviewer ||= merge_request.find_reviewer(user)
    end

    def update_state(reviewer_or_assignee)
      reviewer_or_assignee&.update(state: :reviewed)
    end

    def create_remove_attention_request_note
      SystemNoteService.remove_attention_request(merge_request, merge_request.project, current_user, user)
    end
  end
end
