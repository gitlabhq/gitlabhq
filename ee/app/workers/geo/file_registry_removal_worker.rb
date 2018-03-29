module Geo
  class FileRegistryRemovalWorker
    include ApplicationWorker
    include GeoQueue
    include ::Gitlab::Geo::LogHelpers

    def perform(object_type, object_db_id)
      log_info('Executing Geo::FileRegistryRemovalService', id: object_db_id, type: object_type)

      ::Geo::FileRegistryRemovalService.new(object_type, object_db_id).execute
    end
  end
end
