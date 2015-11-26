class GitHooksService
  PreReceiveError = Class.new(StandardError)

  def execute(user, repo_path, oldrev, newrev, ref)
    @repo_path  = repo_path
    @user       = Gitlab::ShellEnv.gl_id(user)
    @oldrev     = oldrev
    @newrev     = newrev
    @ref        = ref

    pre_status = run_hook('pre-receive')

    if pre_status
      yield

      run_hook('post-receive')
    end
  end

  private

  def run_hook(name)
    hook = Gitlab::Git::Hook.new(name, @repo_path)
    status = hook.trigger(@user, @oldrev, @newrev, @ref)

    if !status && (name != 'post-receive')
      raise PreReceiveError.new("Git operation was rejected by #{name} hook")
    end

    status
  end
end
