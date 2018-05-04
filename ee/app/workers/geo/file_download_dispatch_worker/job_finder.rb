module Geo
  class FileDownloadDispatchWorker
    # This class is meant to be inherited, and is responsible for generating
    # batches of job arguments for FileDownloadWorker.
    #
    # The subclass should define
    #
    #   * registry_finder
    #   * EXCEPT_RESOURCE_IDS_KEY
    #   * RESOURCE_ID_KEY
    #   * FILE_SERVICE_OBJECT_TYPE
    #
    class JobFinder
      include Gitlab::Utils::StrongMemoize

      attr_reader :scheduled_file_ids

      def initialize(scheduled_file_ids)
        @scheduled_file_ids = scheduled_file_ids
      end

      def find_unsynced_jobs(batch_size:)
        convert_resource_relation_to_job_args(
          registry_finder.find_unsynced(find_batch_params(batch_size))
        )
      end

      def find_failed_jobs(batch_size:)
        convert_registry_relation_to_job_args(
          registry_finder.find_retryable_failed_registries(find_batch_params(batch_size))
        )
      end

      def find_synced_missing_on_primary_jobs(batch_size:)
        convert_registry_relation_to_job_args(
          registry_finder.find_retryable_synced_missing_on_primary_registries(find_batch_params(batch_size))
        )
      end

      private

      def find_batch_params(batch_size)
        {
          :batch_size => batch_size,
          self.class::EXCEPT_RESOURCE_IDS_KEY => scheduled_file_ids
        }
      end

      def convert_resource_relation_to_job_args(relation)
        relation.pluck(:id).map { |id| [self.class::FILE_SERVICE_OBJECT_TYPE.to_s, id] }
      end

      def convert_registry_relation_to_job_args(relation)
        relation.pluck(self.class::RESOURCE_ID_KEY).map { |id| [self.class::FILE_SERVICE_OBJECT_TYPE.to_s, id] }
      end
    end
  end
end
