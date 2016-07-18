module Commits
  class ChangeService < ::BaseService
    class ValidationError < StandardError; end
    class ChangeError < StandardError; end

    def execute
      @source_project = params[:source_project] || @project
      @target_branch = params[:target_branch]
      @commit = params[:commit]
      @create_merge_request = params[:create_merge_request].present?

      check_push_permissions unless @create_merge_request
      commit
    rescue Repository::CommitError, Gitlab::Git::Repository::InvalidBlobName, GitHooksService::PreReceiveError,
           ValidationError, ChangeError => ex
      error(ex.message)
    end

    def commit
      raise NotImplementedError
    end

    private

    def check_push_permissions
      allowed = ::Gitlab::UserAccess.new(current_user, project: project).can_push_to_branch?(@target_branch)

      unless allowed
        raise ValidationError.new('You are not allowed to push into this branch')
      end

      true
    end

    def create_target_branch(new_branch)
      # Temporary branch exists and contains the change commit
      return success if repository.find_branch(new_branch)

      result = CreateBranchService.new(@project, current_user)
                                  .execute(new_branch, @target_branch, source_project: @source_project)

      if result[:status] == :error
        raise ChangeError, "There was an error creating the source branch: #{result[:message]}"
      end
    end
  end
end
