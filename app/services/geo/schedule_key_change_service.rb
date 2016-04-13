module Geo
  class ScheduleKeyChangeService
    attr_reader :id, :key, :action

    def initialize(params)
      @id = params['id']
      @key = params['key']
      @action = params['event_name']
    end

    def execute
      GeoKeyRefreshWorker.perform_async(@id, @key, @action)
    end
  end
end
