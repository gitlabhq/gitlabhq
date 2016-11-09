class GeoScheduleBackfillWorker
  include Sidekiq::Worker
  include ::GeoDynamicBackoff
  include GeoQueue

  def perform(geo_node_id)
    Geo::ScheduleBackfillService.new(geo_node_id).execute
  end
end
