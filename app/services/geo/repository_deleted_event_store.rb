module Geo
  class RepositoryDeletedEventStore
    attr_reader :project, :repo_path, :wiki_path

    def initialize(project, repo_path:, wiki_path:)
      @project = project
      @repo_path = repo_path
      @wiki_path = wiki_path
    end

    def create
      return unless Gitlab::Geo.primary?

      Geo::EventLog.transaction do
        event_log = Geo::EventLog.new
        deleted_event = Geo::RepositoryDeletedEvent.new(
          project: project,
          repository_storage_name: project.repository.storage,
          repository_storage_path: project.repository_storage_path,
          deleted_path: repo_path,
          deleted_wiki_path: wiki_path,
          deleted_project_name: project.name)
        event_log.repository_deleted_event = deleted_event
        event_log.save
      end
    end
  end
end
