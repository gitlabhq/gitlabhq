class ProjectServiceWorker
  include Sidekiq::Worker

  sidekiq_options queue: :project_web_hook

  def perform(hook_id, data)
    data = data.with_indifferent_access
    Service.find(hook_id).execute(data)
  end
end
