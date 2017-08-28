module Geo
  class RepositoryDestroyService
    attr_reader :id, :name, :path_with_namespace

    def initialize(id, name, path)
      @id = id
      @name = name
      @path_with_namespace = path
    end

    def async_execute
      GeoRepositoryDestroyWorker.perform_async(id, name, path_with_namespace)
    end
  end
end
