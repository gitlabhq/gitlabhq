class ProjectDestroyWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform(project_id, user_id, params)
    begin
      project = Project.find(project_id)
    rescue ActiveRecord::RecordNotFound
      return
    end

    user = User.find(user_id)

    ::Projects::DestroyService.new(project, user, params).execute
  end
end
