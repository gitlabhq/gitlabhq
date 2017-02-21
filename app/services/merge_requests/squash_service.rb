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
        %W(worktree add --no-checkout --detach #{tree_path}),
        repository.path_to_repo,
        git_env,
        'add worktree for squash'
      )

      configure_sparse_checkout

      diff = git_command(%W(diff --binary #{diff_range}))
      apply = git_command(%w(apply --index))

      run_command(
        ["#{diff.join(' ')} | #{apply.join(' ')}"],
        tree_path,
        git_env,
        'apply patch'
      )

      run_git_command(
        %W(commit --no-verify -m #{merge_request.title}),
        tree_path,
        git_env.merge('GIT_COMMITTER_NAME' => current_user.name,
                      'GIT_COMMITTER_EMAIL' => current_user.email,
                      'GIT_AUTHOR_NAME' => merge_request.author.name,
                      'GIT_AUTHOR_EMAIL' => merge_request.author.email),
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
      clean_worktree
    end

    def tree_path
      @tree_path ||= merge_request.squash_dir_path
    end

    def diff_range
      @diff_range ||= "#{merge_request.diff_start_sha}...#{merge_request.diff_head_sha}"
    end

    def worktree_path
      @worktree_path ||= File.join(repository.path_to_repo, 'worktrees', merge_request.id.to_s)
    end

    def clean_worktree
      FileUtils.rm_rf(worktree_path) if File.exist?(worktree_path)
    end

    # Adding a worktree means checking out the repository. For large repos, this
    # can be very expensive, so set up sparse checkout for the worktree to only
    # check out the files we're interested in.
    #
    def configure_sparse_checkout
      run_git_command(
        %w(config core.sparseCheckout true),
        repository.path_to_repo,
        git_env,
        'configure sparse checkout'
      )

      # Get the same diff we'll apply, excluding added files. (We can't check
      # out files on the target branch if they don't exist yet!)
      #
      diff_files = run_git_command(
        %W(diff --name-only --diff-filter=a --binary #{diff_range}),
        repository.path_to_repo,
        git_env,
        'get files in diff'
      )

      # If only new files are introduced by this MR, then our sparse checkout
      # doesn't need to have any files at all.
      #
      unless diff_files.empty?
        worktree_info = File.join(worktree_path, 'info')

        FileUtils.mkdir_p(worktree_info) unless File.directory?(worktree_info)

        File.write(File.join(worktree_info, 'sparse-checkout'), diff_files)
      end

      run_git_command(
        %W(checkout --detach #{merge_request.target_branch}),
        tree_path,
        git_env,
        'check out target branch'
      )
    end
  end
end
