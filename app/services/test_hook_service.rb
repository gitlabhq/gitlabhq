class TestHookService
  def execute(hook, current_user)
    data = Gitlab::PushDataBuilder.build_sample(hook.project, current_user)
    hook.execute(data, 'push_hooks')
  end
end
