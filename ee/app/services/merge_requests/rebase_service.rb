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
        log_error('Rebase task canceled: Another rebase is already in progress', save_message_on_model: true)
        return false
      end

      run_git_command(
        %W(worktree add --detach #{tree_path} #{merge_request.source_branch}),
        repository.path_to_repo,
        git_env,
        'add worktree for rebase'
      )

      run_git_command(
        %W(pull --rebase #{target_project.repository.path_to_repo} #{merge_request.target_branch}),
        tree_path,
        git_env.merge('GIT_COMMITTER_NAME' => current_user.name,
                      'GIT_COMMITTER_EMAIL' => current_user.email),
        'rebase branch'
      )

      rebase_sha = run_git_command(
        %w(rev-parse HEAD),
        tree_path,
        git_env,
        'get SHA of rebased branch'
      )

      Gitlab::Git::OperationService.new(current_user, project.repository.raw_repository)
        .update_branch(merge_request.source_branch, rebase_sha, merge_request.source_branch_sha)

      merge_request.update_attributes(rebase_commit_sha: rebase_sha)

      true
    rescue GitCommandError
      false
    rescue => e
      log_error('Failed to rebase branch:')
      log_error(e.message, save_message_on_model: true)
      false
    ensure
      clean_dir
    end

    private

    def tree_path
      @tree_path ||= merge_request.rebase_dir_path
    end
  end
end
