module Files
  class BaseService < ::BaseService
    ValidationError = Class.new(StandardError)

    def execute
      @start_project = params[:start_project] || @project
      @start_branch = params[:start_branch]
      @target_branch = params[:target_branch]

      @commit_message = params[:commit_message]
      @file_path      = params[:file_path]
      @previous_path  = params[:previous_path]
      @file_content   = if params[:file_content_encoding] == 'base64'
                          Base64.decode64(params[:file_content])
                        else
                          params[:file_content]
                        end
      @last_commit_sha = params[:last_commit_sha]
      @author_email    = params[:author_email]
      @author_name     = params[:author_name]

      # Validate parameters
      validate

      # Create new branch if it different from start_branch
      validate_target_branch if different_branch?

      result = commit
      if result
        success(result: result)
      else
        error('Something went wrong. Your changes were not committed')
      end
    rescue Repository::CommitError, Gitlab::Git::Repository::InvalidBlobName, GitHooksService::PreReceiveError, ValidationError => ex
      error(ex.message)
    end

    private

    def different_branch?
      @start_branch != @target_branch || @start_project != @project
    end

    def file_has_changed?
      return false unless @last_commit_sha && last_commit

      @last_commit_sha != last_commit.sha
    end

    def raise_error(message)
      raise ValidationError.new(message)
    end

    def validate
      allowed = ::Gitlab::UserAccess.new(current_user, project: project).can_push_to_branch?(@target_branch)

      unless allowed
        raise_error("You are not allowed to push into this branch")
      end

      if !@start_project.empty_repo? && !@start_project.repository.branch_exists?(@start_branch)
        raise ValidationError, 'You can only create or edit files when you are on a branch'
      end

      if !project.empty_repo? && different_branch? && repository.branch_exists?(@branch_name)
        raise ValidationError, "A branch called #{@branch_name} already exists. Switch to that branch in order to make changes"
      end
    end

    def validate_target_branch
      result = ValidateNewBranchService.new(project, current_user).
        execute(@target_branch)

      if result[:status] == :error
        raise_error("Something went wrong when we tried to create #{@target_branch} for you: #{result[:message]}")
      end
    end
  end
end
