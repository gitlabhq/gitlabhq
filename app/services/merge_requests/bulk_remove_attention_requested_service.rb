# frozen_string_literal: true

module MergeRequests
  class BulkRemoveAttentionRequestedService < MergeRequests::BaseService
    attr_accessor :merge_request

    def initialize(project:, current_user:, merge_request:)
      super(project: project, current_user: current_user)

      @merge_request = merge_request
    end

    def execute
      return error("Invalid permissions") unless can?(current_user, :update_merge_request, merge_request)

      merge_request.merge_request_assignees.update_all(state: :reviewed)
      merge_request.merge_request_reviewers.update_all(state: :reviewed)

      success
    end
  end
end
