# frozen_string_literal: true

module MergeRequests
  class MergeabilityCheckService < ::BaseService
    delegate :project, to: :@merge_request
    delegate :repository, to: :project

    def initialize(merge_request)
      @merge_request = merge_request
    end

    # Updates the MR merge_status. Whenever it switches to a can_be_merged state,
    # the merge-ref is refreshed.
    #
    # Returns a ServiceResponse indicating merge_status is/became can_be_merged
    # and the merge-ref is synced. Success in case of being/becoming mergeable,
    # error otherwise.
    def execute
      return ServiceResponse.error('Invalid argument') unless merge_request
      return ServiceResponse.error('Unsupported operation') if Gitlab::Database.read_only?

      update_merge_status

      unless merge_request.can_be_merged?
        return ServiceResponse.error(message: 'Merge request is not mergeable')
      end

      ServiceResponse.success
    end

    private

    attr_reader :merge_request

    def update_merge_status
      return unless merge_request.recheck_merge_status?

      if can_git_merge?
        merge_to_ref && merge_request.mark_as_mergeable
      else
        merge_request.mark_as_unmergeable
      end
    end

    def can_git_merge?
      !merge_request.broken? && repository.can_be_merged?(merge_request.diff_head_sha, merge_request.target_branch)
    end

    def merge_to_ref
      result = MergeRequests::MergeToRefService.new(project, merge_request.author).execute(merge_request)
      result[:status] == :success
    end
  end
end
