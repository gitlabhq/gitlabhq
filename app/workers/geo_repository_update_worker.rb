class GeoRepositoryUpdateWorker
  include Sidekiq::Worker
  include Gitlab::ShellAdapter

  sidekiq_options queue: :default

  attr_accessor :project

  def perform(project_id, clone_url)
    @project = Project.find(project_id)

    fetch_repository(clone_url)
  end

  private

  def fetch_repository(remote_url)
    @project.create_repository unless @project.repository_exists?
    @project.repository.fetch_geo_mirror(remote_url)
  end
end
