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
      repository.rebase(current_user, merge_request, skip_ci: @skip_ci)

      true
    rescue StandardError => e
      log_error(exception: e, message: REBASE_ERROR, save_message_on_model: true)

      false
    ensure
      merge_request.update_column(:rebase_jid, nil)
    end
  end
end
