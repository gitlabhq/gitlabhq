module Geo
  class ScheduleRepoCreateService
    attr_reader :id

    def initialize(params)
      @id = params['project_id']
    end

    def execute
      GeoRepositoryCreateWorker.perform_async(id)
    end
  end
end
