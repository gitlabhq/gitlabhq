module Geo
  class FileDownloadDispatchWorker
    class JobArtifactJobFinder < JobFinder
      RESOURCE_ID_KEY = :artifact_id
      EXCEPT_RESOURCE_IDS_KEY = :except_artifact_ids
      FILE_SERVICE_OBJECT_TYPE = :job_artifact

      def registry_finder
        @registry_finder ||= Geo::JobArtifactRegistryFinder.new(current_node: Gitlab::Geo.current_node)
      end
    end
  end
end
