module Geo
  class FileDownloadWorker
    include ApplicationWorker
    include GeoQueue

    sidekiq_options retry: 3, dead: false

    def perform(object_type, object_id)
      Geo::FileDownloadService.new(object_type.to_sym, object_id).execute
    end
  end
end
