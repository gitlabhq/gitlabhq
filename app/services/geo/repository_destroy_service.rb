module Geo
  class RepositoryDestroyService
    attr_reader :id, :name, :disk_path, :storage_name

    def initialize(id, name, disk_path, storage_name)
      @id = id
      @name = name
      @disk_path = disk_path
      @storage_name = storage_name
    end

    def async_execute
      GeoRepositoryDestroyWorker.perform_async(id, name, disk_path, storage_name)
    end

    def execute
      ::Projects::DestroyService.new(deleted_project, nil).geo_replicate
    end

    private

    def deleted_project
      # We don't have access to the original model anymore, so we are
      # rebuilding only what our service class requires
      ::Geo::DeletedProject.new(id: id,
                                name: name,
                                full_path: disk_path,
                                repository_storage: storage_name)
    end
  end
end
