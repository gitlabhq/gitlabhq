class TestHookService
  def execute(hook, current_user)
    interactor = Projects::Repository::SamplePush
    result = interactor.perform(project: project, user: current_user)

    hook.execute(result[:push_data])
    true
  rescue SocketError
    false
  end
end
