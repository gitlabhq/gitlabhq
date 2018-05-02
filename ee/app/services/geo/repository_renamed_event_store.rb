module Geo
  class RepositoryRenamedEventStore < EventStore
    self.event_type = :repository_renamed_event

    private

    def build_event
      Geo::RepositoryRenamedEvent.new(
        project: project,
        repository_storage_name: project.repository.storage,
        old_path_with_namespace: old_path_with_namespace,
        new_path_with_namespace: project.disk_path,
        old_wiki_path_with_namespace: old_wiki_path_with_namespace,
        new_wiki_path_with_namespace: new_wiki_path_with_namespace,
        old_path: old_path,
        new_path: project.path
      )
    end

    def old_path
      params.fetch(:old_path)
    end

    def old_path_with_namespace
      params.fetch(:old_path_with_namespace)
    end

    def old_wiki_path_with_namespace
      "#{old_path_with_namespace}.wiki"
    end

    def new_wiki_path_with_namespace
      project.wiki.disk_path
    end
  end
end
