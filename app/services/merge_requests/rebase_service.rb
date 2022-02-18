# frozen_string_literal: true

module MergeRequests
  class RebaseService < MergeRequests::BaseService
    REBASE_ERROR = 'Rebase failed: Rebase locally, resolve all conflicts, then push the branch.'

    attr_reader :merge_request, :rebase_error

    def execute(merge_request, skip_ci: false)
      @merge_request = merge_request
      @skip_ci = skip_ci

      if rebase
        success
      else
        error(rebase_error)
      end
    end

    def rebase
      repository.rebase(current_user, merge_request, skip_ci: @skip_ci)

      true
    rescue StandardError => e
      set_rebase_error(e)
      log_error(exception: e, message: rebase_error, save_message_on_model: true)

      false
    ensure
      merge_request.update_column(:rebase_jid, nil)
    end

    private

    def set_rebase_error(exception)
      @rebase_error =
        if exception.is_a?(Gitlab::Git::PreReceiveError)
          "The rebase pre-receive hook failed: #{exception.message}."
        else
          REBASE_ERROR
        end
    end
  end
end
