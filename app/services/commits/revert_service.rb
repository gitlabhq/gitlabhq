module Commits
  class RevertService < ::BaseService
    class ValidationError < StandardError; end

    def execute
      @source_project = params[:source_project] || @project
      @target_branch = params[:target_branch]
      @commit = params[:commit]
      @create_merge_request = params[:create_merge_request].present?

      # Check push permissions to branch
      validate

      if commit
        success
      else
        error("Sorry, we cannot revert this #{params[:revert_type_title]} automatically.
              It may have already been reverted, or a more recent commit may
              have updated some of its content.")
      end
    rescue Repository::CommitError, Gitlab::Git::Repository::InvalidBlobName, GitHooksService::PreReceiveError, ValidationError => ex
      error(ex.message)
    end

    def commit
      if @create_merge_request
        repository.revert(current_user, @commit, @target_branch, @commit.revert_branch_name)
      else
        repository.revert(current_user, @commit, @target_branch)
      end
    end

    private

    def raise_error(message)
      raise ValidationError.new(message)
    end

    def validate
      allowed = ::Gitlab::GitAccess.new(current_user, project).can_push_to_branch?(@target_branch)

      unless allowed
        raise_error("You are not allowed to push into this branch")
      end
    end
  end
end
