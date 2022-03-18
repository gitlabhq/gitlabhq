# frozen_string_literal: true

module MergeRequests
  class BulkRemoveAttentionRequestedService < MergeRequests::BaseService
    attr_accessor :merge_request
    attr_accessor :users

    def initialize(project:, current_user:, merge_request:, users:)
      super(project: project, current_user: current_user)

      @merge_request = merge_request
      @users = users
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def execute
      return error("Invalid permissions") unless can?(current_user, :update_merge_request, merge_request)

      merge_request.merge_request_assignees.where(user_id: users).update_all(state: :reviewed)
      merge_request.merge_request_reviewers.where(user_id: users).update_all(state: :reviewed)

      users.each { |user| user.invalidate_attention_requested_count }

      success
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
