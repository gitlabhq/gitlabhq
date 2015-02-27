class GitTagPushService
  attr_accessor :project, :user, :push_data

  def execute(project, user, oldrev, newrev, ref)
    @project, @user = project, user
    @push_data = create_push_data(oldrev, newrev, ref)

    EventCreateService.new.push(project, user, @push_data)
    project.repository.expire_cache
    project.execute_hooks(@push_data.dup, :tag_push_hooks)

    if project.gitlab_ci?
      project.gitlab_ci_service.async_execute(@push_data)
    end

    true
  end

  private

  def create_push_data(oldrev, newrev, ref)
    Gitlab::PushDataBuilder.
      build(project, user, oldrev, newrev, ref, [])
  end
end
