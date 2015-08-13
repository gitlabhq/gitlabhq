class PreCommitService < BaseService
  include Gitlab::Popen

  attr_reader :changes, :repo_path

  def execute(sha, branch)
    commit = repository.commit(sha)
    full_ref = Gitlab::Git::BRANCH_REF_PREFIX + branch
    old_sha = commit.parent_id || Gitlab::Git::BLANK_SHA
    @changes = "#{old_sha} #{sha} #{full_ref}"
    @repo_path = repository.path_to_repo

    pre_receive
  end

  private

  def pre_receive
    hook = hook_file('pre-receive', repo_path)
    return true if hook.nil?
    call_receive_hook(hook)
  end

  def call_receive_hook(hook)
    # function  will return true if succesful
    exit_status = false

    vars = {
      'GL_ID' => Gitlab::ShellEnv.gl_id(current_user),
      'PWD' => repo_path
    }

    options = {
      chdir: repo_path
    }

    # we combine both stdout and stderr as we don't know what stream
    # will be used by the custom hook
    Open3.popen2e(vars, hook, options) do |stdin, stdout_stderr, wait_thr|
      exit_status = true
      stdin.sync = true

      # in git, pre- and post- receive hooks may just exit without
      # reading stdin. We catch the exception to avoid a broken pipe
      # warning
      begin
        # inject all the changes as stdin to the hook
        changes.lines do |line|
          stdin.puts line
        end
      rescue Errno::EPIPE
      end

      # need to close stdin before reading stdout
      stdin.close

      # only output stdut_stderr if scripts doesn't return 0
      unless wait_thr.value == 0
        exit_status = false
      end
    end

    exit_status
  end

  def hook_file(hook_type, repo_path)
    hook_path = File.join(repo_path.strip, 'hooks')
    hook_file = "#{hook_path}/#{hook_type}"
    hook_file if File.exist?(hook_file)
  end
end
