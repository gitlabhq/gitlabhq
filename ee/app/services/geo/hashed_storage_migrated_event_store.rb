module Geo
  class HashedStorageMigratedEventStore < EventStore
    self.event_type = :hashed_storage_migrated_event

    private

    def build_event
      Geo::HashedStorageMigratedEvent.new(
        project: project,
        old_storage_version: old_storage_version,
        new_storage_version: project.storage_version,
        repository_storage_name: project.repository.storage,
        old_disk_path: old_disk_path,
        new_disk_path: project.disk_path,
        old_wiki_disk_path: old_wiki_disk_path,
        new_wiki_disk_path: project.wiki.disk_path
      )
    end

    def old_storage_version
      params.fetch(:old_storage_version)
    end

    def old_disk_path
      params.fetch(:old_disk_path)
    end

    def old_wiki_disk_path
      params.fetch(:old_wiki_disk_path)
    end
  end
end
