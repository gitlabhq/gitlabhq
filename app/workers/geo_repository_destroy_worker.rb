class GeoRepositoryDestroyWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform(id, name, path_with_namespace)
    # We don't have access to the original model anymore, so we are
    # rebuilding only what our service class requires
    project = FakeProject.new(id, name, path_with_namespace)

    ::Projects::DestroyService.new(project, nil).geo_replicate
  end

  FakeProject = Struct.new(:id, :name, :path_with_namespace) do
    def repository
      @repository ||= Repository.new(path_with_namespace, self)
    end
  end
end
