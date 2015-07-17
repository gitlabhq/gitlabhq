class ProjectCacheWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform(project_id)
    Project.find(project_id).repository.build_cache
  end
end
