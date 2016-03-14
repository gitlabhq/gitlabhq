class GitTagPushService
  attr_accessor :project, :user, :push_data

  def execute(project, user, oldrev, newrev, ref)
    project.repository.before_push_tag

    @project, @user = project, user
    @push_data = build_push_data(oldrev, newrev, ref)

    EventCreateService.new.push(project, user, @push_data)
    project.execute_hooks(@push_data.dup, :tag_push_hooks)
    project.execute_services(@push_data.dup, :tag_push_hooks)
    CreateCommitBuildsService.new.execute(project, @user, @push_data)
    ProjectCacheWorker.perform_async(project.id)

    true
  end

  private

  def build_push_data(oldrev, newrev, ref)
    commits = []
    message = nil

    if !Gitlab::Git.blank_ref?(newrev)
      tag_name = Gitlab::Git.ref_name(ref)
      tag = project.repository.find_tag(tag_name)
      if tag && tag.target == newrev
        commit = project.commit(tag.target)
        commits = [commit].compact
        message = tag.message
      end
    end

    Gitlab::PushDataBuilder.
      build(project, user, oldrev, newrev, ref, commits, message)
  end
end
