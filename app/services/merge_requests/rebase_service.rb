# frozen_string_literal: true

module MergeRequests
  class RebaseService < MergeRequests::BaseService
    REBASE_ERROR = 'Rebase failed. Please rebase locally'

    attr_reader :merge_request

    def execute(merge_request, skip_ci: false)
      @merge_request = merge_request
      @skip_ci = skip_ci

      if rebase
        success
      else
        error(REBASE_ERROR)
      end
    end

    def rebase
      # Ensure Gitaly isn't already running a rebase
      if source_project.repository.rebase_in_progress?(merge_request.id)
        log_error(exception: nil, message: 'Rebase task canceled: Another rebase is already in progress', save_message_on_model: true)
        return false
      end

      repository.rebase(current_user, merge_request, skip_ci: @skip_ci)

      true
    rescue => e
      log_error(exception: e, message: REBASE_ERROR, save_message_on_model: true)

      false
    ensure
      merge_request.update_column(:rebase_jid, nil)
    end
  end
end
