require 'securerandom'

module MergeRequests
  class SquashService < MergeRequests::WorkingCopyBaseService
    attr_reader :repository, :rugged

    def execute(merge_request)
      @merge_request = merge_request
      @repository = target_project.repository
      @rugged = repository.rugged

      squash || error('Failed to squash. Should be done manually')
    end

    def squash
      if merge_request.commits_count <= 1
        return success(squash_sha: merge_request.diff_head_sha)
      end

      if merge_request.squash_in_progress?
        log_error('Squash task canceled: Another squash is already in progress')
        return false
      end

      run_git_command(
        %W(worktree add #{tree_path} #{merge_request.target_branch} --detach),
        repository.path_to_repo,
        git_env,
        'add worktree for squash'
      )

      run_git_command(%w(apply --cached), tree_path, git_env, 'apply patch') do |stdin|
        stdin.puts(merge_request_to_patch)
      end

      run_git_command(
        %W(commit -C #{merge_request.diff_head_sha}),
        tree_path,
        git_env.merge('GIT_COMMITTER_NAME' => current_user.name, 'GIT_COMMITTER_EMAIL' => current_user.email),
        'commit squashed changes'
      )

      squash_sha = run_git_command(
        %w(rev-parse HEAD),
        tree_path,
        git_env,
        'get SHA of squashed commit'
      )

      success(squash_sha: squash_sha)
    rescue GitCommandError
      false
    rescue => e
      log_error("Failed to squash merge request #{merge_request.to_reference(full: true)}:")
      log_error(e.message)
      false
    ensure
      clean_dir
    end

    def tree_path
      @tree_path ||= merge_request.squash_dir_path
    end

    def merge_request_to_patch
      @merge_request_to_patch ||= rugged.diff(merge_request.diff_base_sha, merge_request.diff_head_sha).patch
    end
  end
end
