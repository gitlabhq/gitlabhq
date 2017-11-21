class GeoRepositoryDestroyWorker
  include Sidekiq::Worker
  include GeoQueue
  include Gitlab::ShellAdapter

  def perform(id, name, disk_path, storage_name)
    Geo::RepositoryDestroyService.new(id, name, disk_path, storage_name).execute
  end
end
