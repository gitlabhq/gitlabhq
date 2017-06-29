class ProjectDestroyWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def perform(project_id, user_id, params)
    project = Project.find(project_id)
    user = User.find(user_id)

    ::Projects::DestroyService.new(project, user, params.symbolize_keys).execute
  rescue Exception => error # rubocop:disable Lint/RescueException
    project&.update_attributes(delete_error: error.message, pending_delete: false)
    Rails.logger.error("Deletion failed on #{project&.full_path} with the following message: #{error.message}")

    raise
  end
end
