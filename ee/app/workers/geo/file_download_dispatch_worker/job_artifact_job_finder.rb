module Geo
  class FileDownloadDispatchWorker
    class JobArtifactJobFinder < JobFinder
      def resource_type
        :job_artifact
      end

      def resource_id_prefix
        :artifact
      end

      def find_unsynced_jobs(batch_size:)
        registry_finder.find_unsynced_job_artifacts(batch_size: batch_size, except_artifact_ids: scheduled_file_ids)
          .pluck(:id)
          .map { |id| ['job_artifact', id] }
      end

      def find_failed_jobs(batch_size:)
        find_failed_registries(batch_size: batch_size).pluck(:artifact_id).map { |id| ['job_artifact', id] }
      end

      def find_synced_missing_on_primary_jobs(batch_size:)
        find_synced_missing_on_primary_registries(batch_size: batch_size).pluck(:artifact_id).map { |id| ['job_artifact', id] }
      end
    end
  end
end
