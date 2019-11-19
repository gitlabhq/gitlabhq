# frozen_string_literal: true

module MergeRequests
  class RebaseService < MergeRequests::BaseService
    include Git::Logger

    REBASE_ERROR = 'Rebase failed. Please rebase locally'

    attr_reader :merge_request

    def execute(merge_request)
      @merge_request = merge_request

      if rebase
        success
      else
        error(REBASE_ERROR)
      end
    end

    def rebase
      # Ensure Gitaly isn't already running a rebase
      if source_project.repository.rebase_in_progress?(merge_request.id)
        log_error('Rebase task canceled: Another rebase is already in progress', save_message_on_model: true)
        return false
      end

      repository.rebase(current_user, merge_request)

      true
    rescue => e
      log_error(REBASE_ERROR, save_message_on_model: true)
      log_error(e.message)
      false
    ensure
      merge_request.update_column(:rebase_jid, nil)
    end
  end
end
