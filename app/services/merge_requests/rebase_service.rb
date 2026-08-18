# frozen_string_literal: true

module MergeRequests
  class RebaseService < MergeRequests::BaseService
    REBASE_ERROR = 'Rebase failed: Rebase locally, resolve all conflicts, then push the branch.'

    # Machine-readable failure reasons surfaced on the #execute ServiceResponse
    # (ServiceResponse#reason). Callers such as RebaseWorker's UX SLI reference
    # these directly to tell an expected user outcome apart from a system fault.
    REASON_CONFLICT = :conflict
    REASON_SOURCE_BRANCH_MISSING = :source_branch_missing
    REASON_PRE_RECEIVE = :pre_receive
    REASON_COMMAND_ERROR = :command_error
    REASON_UNKNOWN = :unknown

    SourceBranchMissingError = Class.new(Gitlab::Git::Repository::GitError)

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
        ServiceResponse.success
      else
        ServiceResponse.error(message: rebase_error, reason: @rebase_error_reason)
      end
    end

    def rebase
      raise SourceBranchMissingError, _('Source branch does not exist') unless
        merge_request.source_branch_exists?

      repository.rebase(current_user, merge_request, skip_ci: @skip_ci)

      true
    rescue StandardError => e
      set_rebase_error(e)
      log_error(
        exception: e,
        message: rebase_error,
        save_message_on_model: true,
        track_exception: !e.is_a?(Gitlab::Git::Repository::GitError)
      )

      false
    ensure
      merge_request.update_column(:rebase_jid, nil)
    end

    private

    # Categorises the failure into a machine-readable reason (see REASON_*) so
    # callers such as RebaseWorker's UX SLI can tell an expected user outcome
    # (conflict, push rules, missing branch) apart from an unexpected system
    # failure. The reason is surfaced on the #execute ServiceResponse.
    def set_rebase_error(exception)
      @rebase_error, @rebase_error_reason =
        case exception
        when SourceBranchMissingError
          [exception.message, REASON_SOURCE_BRANCH_MISSING]
        when Gitlab::Git::PreReceiveError
          ["The rebase pre-receive hook failed: #{exception.message}.", REASON_PRE_RECEIVE]
        when Gitlab::Git::CommandError
          ["Rebase failed: #{exception.message}.", REASON_COMMAND_ERROR]
        when Gitlab::Git::Repository::GitError
          [REBASE_ERROR, REASON_CONFLICT]
        else
          [REBASE_ERROR, REASON_UNKNOWN]
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
