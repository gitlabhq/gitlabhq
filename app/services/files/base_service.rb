module Files
  class BaseService < ::BaseService
    class ValidationError < StandardError; end

    def execute
      @source_project = params[:source_project] || @project
      @source_branch = params[:source_branch]
      @target_branch  = params[:target_branch]

      @commit_message = params[:commit_message]
      @file_path      = params[:file_path]
      @previous_path  = params[:previous_path]
      @file_content   = if params[:file_content_encoding] == 'base64'
                          Base64.decode64(params[:file_content])
                        else
                          params[:file_content]
                        end
      @last_commit_sha = params[:last_commit_sha]

      # Validate parameters
      validate

      # Create new branch if it different from source_branch
      if different_branch?
        create_target_branch
      end

      if commit
        success
      else
        error('Something went wrong. Your changes were not committed')
      end
    rescue Repository::CommitError, Gitlab::Git::Repository::InvalidBlobName, GitHooksService::PreReceiveError, ValidationError => ex
      error(ex.message)
    end

    private

    def different_branch?
      @source_branch != @target_branch || @source_project != @project
    end

    def raise_error(message)
      raise ValidationError.new(message)
    end

    def validate
      allowed = ::Gitlab::UserAccess.new(current_user, project: project).can_push_to_branch?(@target_branch)

      unless allowed
        raise_error("You are not allowed to push into this branch")
      end

      unless project.empty_repo?
        unless @source_project.repository.branch_names.include?(@source_branch)
          raise_error('You can only create or edit files when you are on a branch')
        end

        if different_branch?
          if repository.branch_names.include?(@target_branch)
            raise_error('Branch with such name already exists. You need to switch to this branch in order to make changes')
          end
        end
      end
    end

    def create_target_branch
      result = CreateBranchService.new(project, current_user).execute(@target_branch, @source_branch, source_project: @source_project)

      unless result[:status] == :success
        raise_error("Something went wrong when we tried to create #{@target_branch} for you: #{result[:message]}")
      end
    end

    def push_rule
      project.push_rule
    end
  end
end
