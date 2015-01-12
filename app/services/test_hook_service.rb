class TestHookService
  def execute(hook, current_user)
    data = Gitlab::PushDataBuilder.build(hook.project, current_user)
    hook.execute(data)
  end
end
