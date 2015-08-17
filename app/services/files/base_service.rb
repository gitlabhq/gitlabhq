module Files
  class BaseService < ::BaseService
    class ValidationError < StandardError; end

    def execute
      @current_branch = params[:current_branch]
      @target_branch  = params[:target_branch]
      @commit_message = params[:commit_message]
      @file_path      = params[:file_path]
      @file_content   = if params[:file_content_encoding] == 'base64'
                          Base64.decode64(params[:file_content])
                        else
                          params[:file_content]
                        end

      # Validate parameters
      validate

      # Create new branch if it different from current_branch
      if @target_branch != @current_branch
        create_target_branch
      end

      if sha = commit
        success
      else
        error("Something went wrong. Your changes were not committed")
      end
    rescue Repository::CommitError, Repository::PreReceiveError, ValidationError => ex
      error(ex.message)
    end

    private

    def current_branch
      @current_branch ||= params[:current_branch]
    end

    def target_branch
      @target_branch ||= params[:target_branch]
    end

    def raise_error(message)
      raise ValidationError.new(message)
    end

    def validate
      allowed = ::Gitlab::GitAccess.new(current_user, project).can_push_to_branch?(@target_branch)

      unless allowed
        raise_error("You are not allowed to push into this branch")
      end

      unless project.empty_repo?
        unless repository.branch_names.include?(@current_branch)
          raise_error("You can only create files if you are on top of a branch")
        end

        if @current_branch != @target_branch
          if repository.branch_names.include?(@target_branch)
            raise_error("Branch with such name already exists. You need to switch to this branch in order to make changes")
          end
        end
      end
    end

    def create_target_branch
      result = CreateBranchService.new(project, current_user).execute(@target_branch, @current_branch)

      unless result[:status] == :success
        raise_error("Something went wrong when we tried to create #{@target_branch} for you")
      end
    end
  end
end
