module Files
  class BaseService < ::BaseService
    class ValidationError < StandardError; end

    def execute
      @source_project = params[:source_project] || @project
      @source_branch = params[:source_branch]
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

      # Create new branch if it different from source_branch
      if different_branch?
        create_target_branch
      end

      if commit
        success
      else
        error("出错了，你的变更未提交")
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
      allowed = ::Gitlab::GitAccess.new(current_user, project).can_push_to_branch?(@target_branch)

      unless allowed
        raise_error("你不允许推送到此分支")
      end

      unless project.empty_repo?
        unless @source_project.repository.branch_names.include?(@source_branch)
          raise_error("你只能在分支上创建或编辑文件")
        end

        if different_branch?
          if repository.branch_names.include?(@target_branch)
            raise_error("该名称的分支已存在。你需要切换到该分支以进行更改")
          end
        end
      end
    end

    def create_target_branch
      result = CreateBranchService.new(project, current_user).execute(@target_branch, @source_branch, source_project: @source_project)

      unless result[:status] == :success
        raise_error("为你创建分支 #{@target_branch} 时发生了错误：#{result[:message]}")
      end
    end
  end
end
