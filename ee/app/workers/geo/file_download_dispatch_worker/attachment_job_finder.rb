module Geo
  class FileDownloadDispatchWorker
    class AttachmentJobFinder < JobFinder
      def resource_type
        :attachment
      end

      def except_resource_ids_key
        :except_file_ids
      end

      # Why do we need a different `file_type` for each Uploader? Why not just use 'upload'?
      def find_unsynced_jobs(batch_size:)
        registry_finder.find_unsynced_attachments(batch_size: batch_size, except_file_ids: scheduled_file_ids)
          .pluck(:id, :uploader)
          .map { |id, uploader| [uploader.sub(/Uploader\z/, '').underscore, id] }
      end

      def find_failed_jobs(batch_size:)
        find_failed_registries(batch_size: batch_size).pluck(:file_type, :file_id)
      end

      def find_synced_missing_on_primary_jobs(batch_size:)
        find_synced_missing_on_primary_registries(batch_size: batch_size).pluck(:file_type, :file_id)
      end
    end
  end
end
