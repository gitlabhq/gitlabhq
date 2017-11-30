module MergeRequests
  class RebaseService < MergeRequests::WorkingCopyBaseService
    def execute(merge_request)
      @merge_request = merge_request

      if rebase
        success
      else
        error('Failed to rebase. Should be done manually')
      end
    end

    def rebase
      if merge_request.rebase_in_progress?
        log_error('Rebase task canceled: Another rebase is already in progress', save_message_on_model: true)
        return false
      end

      rebase_sha = repository.rebase(current_user, merge_request)

      merge_request.update_attributes(rebase_commit_sha: rebase_sha)

      true
    rescue => e
      log_error('Failed to rebase branch:')
      log_error(e.message, save_message_on_model: true)
      false
    end
  end
end
