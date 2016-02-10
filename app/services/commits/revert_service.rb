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
        custom_error
      end
    rescue Repository::CommitError, Gitlab::Git::Repository::InvalidBlobName, GitHooksService::PreReceiveError, ValidationError => ex
      error(ex.message)
    end

    def commit
      if @create_merge_request
        # Temporary branch exists and contains the revert commit
        return true if repository.find_branch(@commit.revert_branch_name)
        return false unless create_target_branch

        repository.revert(current_user, @commit, @commit.revert_branch_name)
      else
        repository.revert(current_user, @commit, @target_branch)
      end
    end

    private

    def custom_error
      if @branch_error_msg
        error("There was an error creating the source branch: #{@branch_error_msg}")
      else
        error("Sorry, we cannot revert this #{params[:revert_type_title]} automatically.
              It may have already been reverted, or a more recent commit may
              have updated some of its content.")
      end
    end

    def create_target_branch
      result = CreateBranchService.new(@project, current_user)
                                  .execute(@commit.revert_branch_name, @target_branch, source_project: @source_project)

      @branch_error_msg = result[:message]

      result[:status] != :error
    end

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
