class GeoFileDownloadWorker
  include Sidekiq::Worker
  include GeoQueue

  def perform(object_type, object_id)
    Geo::FileDownloadService.new(object_type.to_sym, object_id).execute
  end
end
