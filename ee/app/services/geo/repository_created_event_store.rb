module Geo
  class RepositoryCreatedEventStore < EventStore
    self.event_type = :repository_created_event

    private

    def build_event
      Geo::RepositoryCreatedEvent.new(
        project: project,
        repository_storage_name: project.repository.storage,
        repo_path: project.disk_path,
        wiki_path: (project.wiki.disk_path if project.wiki_enabled?),
        project_name: project.name
      )
    end
  end
end
