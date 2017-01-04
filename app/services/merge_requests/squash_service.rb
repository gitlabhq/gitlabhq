require 'securerandom'

module MergeRequests
  class SquashService < MergeRequests::BaseService
    include Gitlab::Popen

    attr_reader :merge_request, :repository, :rugged

    def execute(merge_request)
      @merge_request = merge_request
      @repository = merge_request.target_project.repository
      @rugged = repository.rugged

      squash || error('Failed to squash. Should be done manually')
    end

    def squash
      # We will push to this ref, then immediately delete the ref. This is
      # because we don't want a new branch to appear in the UI - we just want
      # the commit to be present in the repo.
      #
      # Squashing would ideally be possible by applying a patch to a bare repo
      # and creating a commit object, in which case wouldn't need this dance.
      #
      temp_branch = SecureRandom.uuid

      if merge_request.squash_in_progress?
        log('Squash task canceled: Another squash is already in progress')
        return false
      end

      # Clone
      output, status = popen(
        %W(git clone -b #{merge_request.target_branch} -- #{repository.path_to_repo} #{tree_path}),
        nil,
        git_env
      )

      unless status.zero?
        log('Failed to clone repository for squash:')
        log(output)
        return false
      end

      # Squash
      output, status = popen(%w(git apply --cached), tree_path, git_env) do |stdin|
        stdin.puts(merge_request_to_patch)
      end

      unless status.zero?
        log('Failed to apply patch:')
        log(output)
        return false
      end

      output, status = popen(
        %W(git commit -C #{merge_request.diff_head_sha}),
        tree_path,
        git_env.merge('GIT_COMMITTER_NAME' => current_user.name, 'GIT_COMMITTER_EMAIL' => current_user.email)
      )

      unless status.zero?
        log('Failed to commit squashed changes:')
        log(output)
        return false
      end

      output, status = popen(%w(git rev-parse HEAD), tree_path, git_env)

      unless status.zero?
        log("Failed to get SHA of squashed branch #{temp_branch}:")
        log(output)
        return false
      end

      target = output.chomp

      # Push to temporary ref
      output, status = popen(%W(git push -f origin HEAD:#{temp_branch}), tree_path, git_env)

      unless status.zero?
        log('Failed to push squashed branch:')
        log(output)
        return false
      end

      repository.rm_branch(current_user, temp_branch, skip_event: true)

      success(squash_oid: target)
    rescue => ex
      log("Failed to squash merge request #{project.path_with_namespace}#{merge_request.to_reference}:")
      log(ex.message)
      false
    ensure
      clean_dir
    end

    def inspect
      ''
    end

    def tree_path
      @tree_path ||= merge_request.squash_dir_path
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

    def merge_request_to_patch
      @merge_request_to_patch ||= rugged.diff(merge_request.diff_base_sha, merge_request.diff_head_sha).patch
    end
  end
end
