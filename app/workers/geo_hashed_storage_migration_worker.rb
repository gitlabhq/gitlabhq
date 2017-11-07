class GeoHashedStorageMigrationWorker
  include Sidekiq::Worker
  include GeoQueue

  def perform(project_id, old_disk_path, new_disk_path)
    Geo::HashedStorageMigrationService.new(project_id, old_disk_path, new_disk_path).execute
  end
end
