module Geo
  class FileDownloadDispatchWorker
    class AttachmentJobFinder < JobFinder
      EXCEPT_RESOURCE_IDS_KEY = :except_file_ids

      def registry_finder
        @registry_finder ||= Geo::AttachmentRegistryFinder.new(current_node: Gitlab::Geo.current_node)
      end

      private

      # Why do we need a different `file_type` for each Uploader? Why not just use 'upload'?
      def convert_resource_relation_to_job_args(relation)
        relation.pluck(:id, :uploader)
                .map { |id, uploader| [uploader.sub(/Uploader\z/, '').underscore, id] }
      end

      def convert_registry_relation_to_job_args(relation)
        relation.pluck(:file_type, :file_id)
      end
    end
  end
end
