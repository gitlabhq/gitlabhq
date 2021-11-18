# frozen_string_literal: true

module MergeRequests
  class ToggleAttentionRequestedService < MergeRequests::BaseService
    attr_accessor :merge_request, :user

    def initialize(project:, current_user:, merge_request:, user:)
      super(project: project, current_user: current_user)

      @merge_request = merge_request
      @user = user
    end

    def execute
      return error("Invalid permissions") unless can?(current_user, :update_merge_request, merge_request)

      if reviewer || assignee
        update_state(reviewer)
        update_state(assignee)

        if reviewer&.attention_requested? || assignee&.attention_requested?
          notity_user
        end

        success
      else
        error("User is not a reviewer or assignee of the merge request")
      end
    end

    private

    def notity_user
      todo_service.create_attention_requested_todo(merge_request, current_user, user)
    end

    def assignee
      merge_request.find_assignee(user)
    end

    def reviewer
      merge_request.find_reviewer(user)
    end

    def update_state(reviewer_or_assignee)
      reviewer_or_assignee&.update(state: reviewer_or_assignee&.attention_requested? ? :reviewed : :attention_requested)
    end
  end
end
