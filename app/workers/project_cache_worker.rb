class ProjectCacheWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform(project_id)
    project = Project.find(project_id)
    project.update_repository_size
    project.update_commit_count

    if project.repository.root_ref
      project.repository.build_cache
    end
  end
end
