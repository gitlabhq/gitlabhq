class GitTagPushService < BaseService
  attr_accessor :push_data

  def execute
    project.repository.after_create if project.empty_repo?
    project.repository.before_push_tag

    @push_data = build_push_data

    EventCreateService.new.push(project, current_user, @push_data)
    SystemHooksService.new.execute_hooks(build_system_push_data.dup, :tag_push_hooks)
    project.execute_hooks(@push_data.dup, :tag_push_hooks)
    project.execute_services(@push_data.dup, :tag_push_hooks)
    CreateCommitBuildsService.new.execute(
      project,
      current_user,
      @push_data,
      mirror_update: params[:mirror_update]
    )
    ProjectCacheWorker.perform_async(project.id)

    true
  end

  private

  def build_push_data
    commits = []
    message = nil

    unless Gitlab::Git.blank_ref?(params[:newrev])
      tag_name = Gitlab::Git.ref_name(params[:ref])
      tag = project.repository.find_tag(tag_name)
      
      if tag && tag.target == params[:newrev]
        commit = project.commit(tag.target)
        commits = [commit].compact
        message = tag.message
      end
    end

    Gitlab::PushDataBuilder.
      build(project, current_user, params[:oldrev], params[:newrev], params[:ref], commits, message)
  end

  def build_system_push_data
    Gitlab::PushDataBuilder.
      build(project, current_user, params[:oldrev], params[:newrev], params[:ref], [], '')
  end
end
