module MergeRequests
  class RebaseService < MergeRequests::WorkingCopyBaseService
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
        log_error('Rebase task canceled: Another rebase is already in progress')
        return false
      end

      run_git_command(
        %W(clone -b #{merge_request.source_branch} -- #{source_project.repository.path_to_repo} #{tree_path}),
        nil,
        git_env,
        'clone repository for rebase'
      )

      run_git_command(
        %W(pull --rebase #{target_project.repository.path_to_repo} #{merge_request.target_branch}),
        tree_path,
        git_env,
        'rebase branch'
      )

      rebase_sha = run_git_command(
        %W(rev-parse #{merge_request.source_branch}),
        tree_path,
        git_env,
        'get SHA of rebased branch'
      )

      merge_request.update_attributes(rebase_commit_sha: rebase_sha)

      run_git_command(
        %W(push -f origin #{merge_request.source_branch}),
        tree_path,
        git_env,
        'push rebased branch'
      )

      true
    rescue GitCommandError
      false
    rescue => e
      log_error('Failed to rebase branch:')
      log_error(e)
      false
    ensure
      clean_dir
    end

    def tree_path
      @tree_path ||= merge_request.rebase_dir_path
    end
  end
end
