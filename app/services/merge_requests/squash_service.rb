# frozen_string_literal: true

module MergeRequests
  class SquashService
    include BaseServiceUtility
    include MergeRequests::ErrorLogger

    def initialize(merge_request:, current_user:, commit_message:)
      @merge_request = merge_request
      @target_project = merge_request.target_project
      @current_user = current_user
      @commit_message = commit_message
    end

    def execute
      # If performing a squash would result in no change, then
      # immediately return a success message without performing a squash
      if merge_request.commits_count == 1 && message&.strip == merge_request.first_commit.safe_message&.strip
        return success(squash_sha: merge_request.diff_head_sha)
      end

      return error(s_("MergeRequests|Squashing not allowed: This project doesn't allow you to squash commits when merging.")) if squash_forbidden?

      squash! || error(s_('MergeRequests|Squashing failed: Squash the commits locally, resolve any conflicts, then push the branch.'))
    end

    private

    attr_reader :merge_request, :target_project, :current_user, :commit_message

    def squash!
      squash_sha = repository.squash(current_user, merge_request, message)

      success(squash_sha: squash_sha)
    rescue StandardError => e
      log_error(exception: e, message: 'Failed to squash merge request')

      false
    end

    def squash_forbidden?
      target_project.squash_never?
    end

    def repository
      target_project.repository
    end

    def message
      commit_message.presence || merge_request.default_squash_commit_message(user: current_user)
    end
  end
end
