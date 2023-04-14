# frozen_string_literal: true

module MergeRequests
  class RebaseService < MergeRequests::BaseService
    REBASE_ERROR = 'Rebase failed: Rebase locally, resolve all conflicts, then push the branch.'

    attr_reader :merge_request, :rebase_error

    def validate(merge_request)
      return error_response(_('Source branch does not exist')) unless
        merge_request.source_branch_exists?

      return error_response(_('Cannot push to source branch')) unless
          user_access.can_push_to_branch?(merge_request.source_branch)

      return error_response(_('Source branch is protected from force push')) unless
          merge_request.permits_force_push?

      ServiceResponse.success
    end

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

    def user_access
      Gitlab::UserAccess.new(current_user, container: project)
    end

    def error_response(message)
      ServiceResponse.error(message: message)
    end
  end
end

::MergeRequests::RebaseService.prepend_mod
