class GeoRepositoryUpdateWorker
  include Sidekiq::Worker
  include Gitlab::ShellAdapter

  sidekiq_options queue: :default

  attr_accessor :project

  def perform(project_id)
    @project = Project.find(project_id)

    fetch_repository(@project.repository, @project.url_to_repo)
  end

  private

  def fetch_repository(repository, remote_url)
    repository.fetch_geo_mirror(remote_url)
  end
end
