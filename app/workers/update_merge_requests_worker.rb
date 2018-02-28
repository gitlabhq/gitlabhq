class UpdateMergeRequestsWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def metrics_tags
    @metrics_tags || {}
  end

  def perform(project_id, user_id, oldrev, newrev, ref)
    project = Project.find_by(id: project_id)
    return unless project

    user = User.find_by(id: user_id)
    return unless user

    @metrics_tags = {
      project_id: project_id,
      user_id: user_id
    }

    MergeRequests::RefreshService.new(project, user).execute(oldrev, newrev, ref)
  end
end
