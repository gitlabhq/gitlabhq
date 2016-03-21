module Geo
  class ScheduleKeyChangeService
    attr_reader :id, :action

    def initialize(key_id, change)
      @id = key_id
      @action = change
    end

    def execute
      GeoKeyRefreshWorker.perform_async(@id, @action)
    end
  end
end
