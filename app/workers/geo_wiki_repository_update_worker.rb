class GeoWikiRepositoryUpdateWorker
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
    # Second .wiki call returns a Gollum::Wiki, and it will always create the physical repository when not found
    if @project.wiki.wiki.exist?
      @project.wiki.repository.fetch_geo_mirror(remote_url)
    end
  end
end
