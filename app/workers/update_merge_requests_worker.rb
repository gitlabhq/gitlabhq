class UpdateMergeRequestsWorker
  include Sidekiq::Worker

  def perform(project_id, user_id, oldrev, newrev, ref)
    project = Project.find_by(id: project_id)
    return unless project

    user = User.find_by(id: user_id)
    return unless user

    MergeRequests::RefreshService.new(project, user).execute(oldrev, newrev, ref)

    push_data = Gitlab::DataBuilder::Push.build(project, user, oldrev, newrev, ref, [])
    SystemHooksService.new.execute_hooks(push_data, :push_hooks)
  end
end
