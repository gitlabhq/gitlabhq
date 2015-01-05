class ProjectServiceWorker
  include Sidekiq::Worker

  sidekiq_options queue: :project_web_hook

  def perform(hook_id, data)
    Service.find(hook_id).execute(data)
  end
end
