module Geo
  class ScheduleKeyChangeService
    attr_reader :id, :key, :action

    def initialize(key_change)
      @id = key_change['id']
      @key = key_change['key']
      @action = key_change['action']
    end

    def execute
      GeoKeyRefreshWorker.perform_async(@id, @key, @action)
    end
  end
end
