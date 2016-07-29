class TestHookService
  def execute(hook, current_user)
    data = Gitlab::PushDataBuilder.build_sample(project(hook), current_user)
    hook.execute(data, 'push_hooks')
  end

  private

  def project(hook)
    if hook.is_a? GroupHook
      hook.group.first_non_empty_project
    else
      hook.project
    end
  end
end
