class GitTagPushService
  attr_accessor :project, :user, :push_data

  def execute(project, user, oldrev, newrev, ref)
    @project, @user = project, user
    
    @push_data = build_push_data(oldrev, newrev, ref)

    EventCreateService.new.push(project, user, @push_data)
    project.execute_hooks(@push_data.dup, :tag_push_hooks)
    project.execute_services(@push_data.dup, :tag_push_hooks)

    project.repository.expire_cache

    true
  end

  private

  def build_push_data(oldrev, newrev, ref)
    Gitlab::PushDataBuilder.build(project, user, oldrev, newrev, ref, [])
  end
end
