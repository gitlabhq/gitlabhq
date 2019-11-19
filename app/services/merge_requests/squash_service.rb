# frozen_string_literal: true

module MergeRequests
  class SquashService < MergeRequests::BaseService
    include Git::Logger

    def execute
      # If performing a squash would result in no change, then
      # immediately return a success message without performing a squash
      if merge_request.commits_count < 2 && message.nil?
        return success(squash_sha: merge_request.diff_head_sha)
      end

      if merge_request.squash_in_progress?
        return error(s_('MergeRequests|Squash task canceled: another squash is already in progress.'))
      end

      squash! || error(s_('MergeRequests|Failed to squash. Should be done manually.'))
    end

    private

    def squash!
      squash_sha = repository.squash(current_user, merge_request, message || merge_request.default_squash_commit_message)

      success(squash_sha: squash_sha)
    rescue => e
      log_error("Failed to squash merge request #{merge_request.to_reference(full: true)}:")
      log_error(e.message)
      false
    end

    def repository
      target_project.repository
    end

    def merge_request
      params[:merge_request]
    end

    def message
      params[:squash_commit_message].presence
    end
  end
end
