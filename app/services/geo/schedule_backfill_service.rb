module Geo
  class ScheduleBackfillService
    attr_accessor :geo_node_id

    def initialize(geo_node_id)
      @geo_node_id = geo_node_id
    end

    def execute
      return if geo_node_id.nil?

      Project.all.select(&:valid_repo?).each do |project|
        GeoBackfillWorker.perform_async(geo_node_id, project.id)
      end
    end
  end
end
