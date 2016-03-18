module Commits
  class RevertService < ::BaseService
    class ValidationError < StandardError; end
    class ReversionError < StandardError; end

    def execute
      @source_project = params[:source_project] || @project
      @target_branch = params[:target_branch]
      @commit = params[:commit]
      @create_merge_request = params[:create_merge_request].present?

      validate and commit
    rescue Repository::CommitError, Gitlab::Git::Repository::InvalidBlobName, GitHooksService::PreReceiveError,
           ValidationError, ReversionError => ex
      error(ex.message)
    end

    def commit
      revert_into = @create_merge_request ? @commit.revert_branch_name : @target_branch
      revert_tree_id = repository.check_revert_content(@commit, @target_branch)

      if revert_tree_id
        create_target_branch(revert_into) if @create_merge_request

        repository.revert(current_user, @commit, revert_into, revert_tree_id)
        success
      else
        error_msg = "Sorry, we cannot revert this #{params[:revert_type_title]} automatically.
                     It may have already been reverted, or a more recent commit may have updated some of its content."
        raise ReversionError, error_msg
      end
    end

    private

    def create_target_branch(new_branch)
      # Temporary branch exists and contains the revert commit
      return success if repository.find_branch(new_branch)

      result = CreateBranchService.new(@project, current_user)
                                  .execute(new_branch, @target_branch, source_project: @source_project)

      if result[:status] == :error
        raise ReversionError, "There was an error creating the source branch: #{result[:message]}"
      end
    end

    def validate
      allowed = ::Gitlab::GitAccess.new(current_user, project).can_push_to_branch?(@target_branch)

      unless allowed
        raise_error('You are not allowed to push into this branch')
      end

      true
    end
  end
end
