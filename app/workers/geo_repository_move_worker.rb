class GeoRepositoryMoveWorker
  include Sidekiq::Worker
  include GeoQueue

  def perform(id, name, old_path_with_namespace, new_path_with_namespace)
    Geo::MoveRepositoryService.new(id, name, old_path_with_namespace, new_path_with_namespace).execute
  end
end
