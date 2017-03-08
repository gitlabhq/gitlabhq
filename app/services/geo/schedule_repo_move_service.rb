module Geo
  class ScheduleRepoMoveService
    attr_reader :id, :name, :old_path_with_namespace, :path_with_namespace

    def initialize(params)
      @id = params['project_id']
      @name = params['name']
      @old_path_with_namespace = params['old_path_with_namespace']
      @path_with_namespace = params['path_with_namespace']
    end

    def execute
      GeoRepositoryMoveWorker.perform_async(id, name, old_path_with_namespace, path_with_namespace)
    end
  end
end
