class GitHooksService
  PreReceiveError = Class.new(StandardError)

  def execute(user, repo_path, oldrev, newrev, ref)
    @repo_path  = repo_path
    @user       = Gitlab::ShellEnv.gl_id(user)
    @oldrev     = oldrev
    @newrev     = newrev
    @ref        = ref

    %w(pre-receive update).each do |hook_name|
      unless run_hook(hook_name)
        raise PreReceiveError.new("Git operation was rejected by #{hook_name} hook")
      end
    end

    yield

    run_hook('post-receive')
  end

  private

  def run_hook(name)
    hook = Gitlab::Git::Hook.new(name, @repo_path)
    hook.trigger(@user, @oldrev, @newrev, @ref)
  end
end
