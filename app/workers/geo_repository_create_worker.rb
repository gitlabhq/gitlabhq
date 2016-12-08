class GeoRepositoryCreateWorker
  include Sidekiq::Worker
  include GeoQueue

  def perform(id)
    project = Project.find(id)

    project.ensure_dir_exist
    project.create_repository unless project.repository_exists?
  end
end
