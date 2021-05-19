# frozen_string_literal: true

module MergeRequests
  class SquashService < MergeRequests::BaseService
    SquashInProgressError = Class.new(RuntimeError)

    def execute
      # If performing a squash would result in no change, then
      # immediately return a success message without performing a squash
      if merge_request.commits_count < 2 && message.nil?
        return success(squash_sha: merge_request.diff_head_sha)
      end

      return error(s_('MergeRequests|This project does not allow squashing commits when merge requests are accepted.')) if squash_forbidden?

      if squash_in_progress?
        return error(s_('MergeRequests|Squash task canceled: another squash is already in progress.'))
      end

      squash! || error(s_('MergeRequests|Failed to squash. Should be done manually.'))

    rescue SquashInProgressError
      error(s_('MergeRequests|An error occurred while checking whether another squash is in progress.'))
    end

    private

    def squash!
      squash_sha = repository.squash(current_user, merge_request, message || merge_request.default_squash_commit_message)

      success(squash_sha: squash_sha)
    rescue StandardError => e
      log_error(exception: e, message: 'Failed to squash merge request')

      false
    end

    def squash_in_progress?
      merge_request.squash_in_progress?
    rescue StandardError => e
      log_error(exception: e, message: 'Failed to check squash in progress')

      raise SquashInProgressError, e.message
    end

    def squash_forbidden?
      target_project.squash_never?
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
