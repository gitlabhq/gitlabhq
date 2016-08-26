module MergeRequests
  # MergeService class
  #
  # Do git merge and in case of success
  # mark merge request as merged and execute all hooks and notifications
  # Executed when you do merge via GitLab UI
  #
  class RebaseService < MergeRequests::BaseService
    include Gitlab::Popen

    attr_reader :merge_request

    def execute(merge_request)
      @merge_request = merge_request

      if rebase
        success
      else
        error('Failed to rebase. Should be done manually')
      end
    end

    def rebase
      if merge_request.rebase_in_progress?
        log('Rebase task canceled: Another rebase is already in progress')
        return false
      end

      # Clone
      output, status = popen(
        %W(git clone -b #{merge_request.source_branch} -- #{source_project.repository.path_to_repo} #{tree_path}),
        nil,
        git_env
      )

      unless status.zero?
        log('Failed to clone repository for rebase:')
        log(output)
        return false
      end

      # Rebase
      output, status = popen(
        %W(git pull --rebase #{target_project.repository.path_to_repo} #{merge_request.target_branch}),
        tree_path,
        git_env
      )

      unless status.zero?
        log('Failed to rebase branch:')
        log(output)
        return false
      end

      output, status = popen(
        %W(git rev-parse #{merge_request.source_branch}),
        tree_path,
        git_env
      )

      unless status.zero?
        log('Failed to get SHA of rebased branch:')
        log(output)
        return false
      end

      merge_request.update_attributes(rebase_commit_sha: output.chomp)
      # Push
      output, status = popen(
        %W(git push -f origin #{merge_request.source_branch}),
        tree_path,
        git_env
      )

      unless status.zero?
        log('Failed to push rebased branch:')
        log(output)
        return false
      end

      true
    rescue => ex
      log('Failed to rebase branch:')
      log(ex.message)
    ensure
      clean_dir
    end

    def source_project
      @source_project ||= merge_request.source_project
    end

    def target_project
      @target_project ||= merge_request.target_project
    end

    def tree_path
      @tree_path ||= merge_request.rebase_dir_path
    end

    def log(message)
      Gitlab::GitLogger.error(message)
    end

    def clean_dir
      FileUtils.rm_rf(tree_path) if File.exist?(tree_path)
    end

    def git_env
      { 'GL_ID' => Gitlab::GlId.gl_id(current_user), 'GL_PROTOCOL' => 'web' }
    end
  end
end
