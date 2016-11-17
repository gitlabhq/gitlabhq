module Geo
  class ScheduleBackfillService
    attr_accessor :geo_node_id

    def initialize(geo_node_id)
      @geo_node_id = geo_node_id
    end

    def execute
      return if geo_node_id.nil?

      Project.find_each(batch_size: 100) do |project|
        GeoBackfillWorker.perform_async(geo_node_id, project.id) if project.valid_repo?
      end
    end
  end
end
