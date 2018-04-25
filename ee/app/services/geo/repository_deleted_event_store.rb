module Geo
  class RepositoryDeletedEventStore < EventStore
    self.event_type = :repository_deleted_event

    private

    def build_event
      Geo::RepositoryDeletedEvent.new(
        project: project,
        repository_storage_name: project.repository.storage,
        deleted_path: params.fetch(:repo_path),
        deleted_wiki_path: params.fetch(:wiki_path),
        deleted_project_name: project.name)
    end
  end
end
