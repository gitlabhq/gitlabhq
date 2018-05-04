module Geo
  class FileDownloadDispatchWorker
    class LfsObjectJobFinder < JobFinder
      RESOURCE_ID_KEY = :file_id
      EXCEPT_RESOURCE_IDS_KEY = :except_file_ids
      FILE_SERVICE_OBJECT_TYPE = :lfs

      def registry_finder
        @registry_finder ||= Geo::LfsObjectRegistryFinder.new(current_node: Gitlab::Geo.current_node)
      end
    end
  end
end
