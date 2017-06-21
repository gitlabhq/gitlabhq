class GeoRepositoryDestroyWorker
  include Sidekiq::Worker
  include GeoQueue

  def perform(id, name, path_with_namespace)
    # We don't have access to the original model anymore, so we are
    # rebuilding only what our service class requires
    project = ::Geo::DeletedProject.new(id: id, name: name, path_with_namespace: path_with_namespace)

    ::Projects::DestroyService.new(project, nil).geo_replicate
  end
end
