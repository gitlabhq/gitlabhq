class TestHookService
  def execute(hook, current_user)
    data = GitPushService.new.sample_data(hook.project, current_user)
    hook.execute(data)
    true
  rescue SocketError
    false
  end
end
