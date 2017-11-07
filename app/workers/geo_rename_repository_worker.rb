class GeoRenameRepositoryWorker
  include Sidekiq::Worker
  include GeoQueue

  def perform(project_id, old_path_with_namespace, new_path_with_namespace)
    Geo::RenameRepositoryService.new(project_id, old_path_with_namespace, new_path_with_namespace).execute
  end
end
