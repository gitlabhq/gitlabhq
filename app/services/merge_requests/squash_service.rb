# frozen_string_literal: true

module MergeRequests
  class SquashService < MergeRequests::WorkingCopyBaseService
    def execute(merge_request)
      @merge_request = merge_request
      @repository = target_project.repository

      squash || error('Failed to squash. Should be done manually.')
    end

    def squash
      if merge_request.commits_count < 2
        return success(squash_sha: merge_request.diff_head_sha)
      end

      if merge_request.squash_in_progress?
        return error('Squash task canceled: another squash is already in progress.')
      end

      squash_sha = repository.squash(current_user, merge_request)

      success(squash_sha: squash_sha)
    rescue => e
      log_error("Failed to squash merge request #{merge_request.to_reference(full: true)}:")
      log_error(e.message)
      false
    end
  end
end
