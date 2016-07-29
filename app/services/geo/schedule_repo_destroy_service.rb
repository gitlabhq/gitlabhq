module Geo
  class ScheduleRepoDestroyService
    attr_reader :id, :name, :path_with_namespace

    def initialize(params)
      @id = params['project_id']
      @name = params['name']
      @path_with_namespace = params['path_with_namespace']
    end

    def execute
      GeoRepositoryDestroyWorker.perform_async(id, name, path_with_namespace)
    end
  end
end
