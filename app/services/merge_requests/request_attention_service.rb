# frozen_string_literal: true

module MergeRequests
  class RequestAttentionService < MergeRequests::BaseService
    attr_accessor :merge_request, :user

    def initialize(project:, current_user:, merge_request:, user:)
      super(project: project, current_user: current_user)

      @merge_request = merge_request
      @user = user
    end

    def execute
      return error("Invalid permissions") unless can?(current_user, :update_merge_request, merge_request)

      if reviewer || assignee
        return success if reviewer&.attention_requested? || assignee&.attention_requested?

        update_state(reviewer)
        update_state(assignee)

        user.invalidate_attention_requested_count
        create_attention_request_note
        notity_user

        if current_user.id != user.id
          remove_attention_requested(merge_request)
        end

        success
      else
        error("User is not a reviewer or assignee of the merge request")
      end
    end

    private

    def notity_user
      notification_service.async.attention_requested_of_merge_request(merge_request, current_user, user)
      todo_service.create_attention_requested_todo(merge_request, current_user, user)
    end

    def create_attention_request_note
      SystemNoteService.request_attention(merge_request, merge_request.project, current_user, user)
    end

    def assignee
      @assignee ||= merge_request.find_assignee(user)
    end

    def reviewer
      @reviewer ||= merge_request.find_reviewer(user)
    end

    def update_state(reviewer_or_assignee)
      reviewer_or_assignee&.update(state: :attention_requested, updated_state_by: current_user)
    end
  end
end
