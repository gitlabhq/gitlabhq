module Geo
  class FileDownloadDispatchWorker
    class LfsObjectJobFinder < JobFinder
      def resource_type
        :lfs_object
      end

      def except_resource_ids_key
        :except_file_ids
      end

      def find_unsynced_jobs(batch_size:)
        registry_finder.find_unsynced_lfs_objects(batch_size: batch_size, except_file_ids: scheduled_file_ids)
          .pluck(:id)
          .map { |id| ['lfs', id] }
      end

      def find_failed_jobs(batch_size:)
        find_failed_registries(batch_size: batch_size).pluck(:file_id).map { |id| ['lfs', id] }
      end

      def find_synced_missing_on_primary_jobs(batch_size:)
        find_synced_missing_on_primary_registries(batch_size: batch_size).pluck(:file_id).map { |id| ['lfs', id] }
      end
    end
  end
end
