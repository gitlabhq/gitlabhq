class GeoRepositoryMoveWorker
  include Sidekiq::Worker
  include GeoQueue

  def perform(id, old_path_with_namespace, new_path_with_namespace)
    Geo::MoveRepositoryService.new(id, old_path_with_namespace, new_path_with_namespace).execute
  end
end
