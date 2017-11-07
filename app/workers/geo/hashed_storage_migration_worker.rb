module Geo
  class HashedStorageMigrationWorker
    include Sidekiq::Worker
    include GeoQueue

    def perform(project_id, old_disk_path, new_disk_path, old_storage_version, new_storage_version)
      Geo::HashedStorageMigrationService.new(
        project_id,
        old_disk_path,
        new_disk_path,
        old_storage_version,
        new_storage_version
      ).execute
    end
  end
end
