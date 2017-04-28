class ProjectDestroyWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def perform(project_id, user_id, params)
    begin
      project = Project.unscoped.find(project_id)
    rescue ActiveRecord::RecordNotFound
      return
    end

    user = User.find(user_id)

    ::Projects::DestroyService.new(project, user, params.symbolize_keys).execute
  rescue StandardError => error
    project.assign_attributes(delete_error: error.message, pending_delete: false)
    project.save!(validate: false)
  end
end
