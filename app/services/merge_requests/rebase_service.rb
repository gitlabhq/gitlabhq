module MergeRequests
  class RebaseService < MergeRequests::WorkingCopyBaseService
    REBASE_ERROR = 'Rebase failed. Please rebase locally'.freeze

    def execute(merge_request)
      @merge_request = merge_request

      if rebase
        success
      else
        error(REBASE_ERROR)
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
      log_error(REBASE_ERROR, save_message_on_model: true)
      log_error(e.message)
      false
    end
  end
end
