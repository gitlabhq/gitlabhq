module Commits
  class RevertService < ::BaseService
    class ValidationError < StandardError; end

    def execute
      @source_project = params[:source_project] || @project
      @target_branch  = params[:target_branch]
      @commit_to_revert = @source_project.commit(params[:revert_commit_id])

      # Check push permissions to branch
      validate

      if commit
        success
      else
        error("Something went wrong. Your changes were not committed")
      end
    rescue Repository::CommitError, Gitlab::Git::Repository::InvalidBlobName, GitHooksService::PreReceiveError, ValidationError => ex
      error(ex.message)
    end

    def commit
      raw_repo = repository.rugged

      # Create branch with revert commit
      reverted = repository.revert(current_user, @commit_to_revert.id,
                                   @commit_to_revert.revert_branch_name, @target_branch,
                                   @commit_to_revert.revert_message)
      repository.rm_branch(current_user, @commit_to_revert.revert_branch_name)

      reverted
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
