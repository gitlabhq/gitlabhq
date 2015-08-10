class PostCommitService < BaseService
  include Gitlab::Popen

  attr_reader :changes

  def execute(sha, branch)
    commit = repository.commit(sha)
    full_ref = 'refs/heads/' + branch
    old_sha = commit.parent_id || Gitlab::Git::BLANK_SHA

    @changes = "#{old_sha} #{sha} #{full_ref}"
    post_receive(@changes, repository.path_to_repo)
  end

  private

  def post_receive(changes, repo_path)
    hook = hook_file('post-receive', repo_path)
    return true if hook.nil?
    call_receive_hook(hook, changes) ? true : false
  end

  def call_receive_hook(hook, changes)
    # function  will return true if succesful
    exit_status = false

    vars = {
      'GL_ID' => Gitlab::ShellEnv.gl_id(current_user),
      'PWD' => repository.path_to_repo
    }

    options = {
      chdir: repository.path_to_repo
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
          stdin.puts (line)
        end
      rescue Errno::EPIPE
      end

      # need to close stdin before reading stdout
      stdin.close

      # only output stdut_stderr if scripts doesn't return 0
      unless wait_thr.value == 0
        exit_status = false
        stdout_stderr.each_line { |line| puts line }
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
