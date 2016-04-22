class GeoRepositoryMoveWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform(id, name, old_path_with_namespace, new_path_with_namespace)
    Geo::MoveRepositoryService.new(id, name, old_path_with_namespace, new_path_with_namespace).execute
  end
end
