# frozen_string_literal: true

module Packages
  module Helm
    class CleanupStaleMetadataCacheWorker
      include ApplicationWorker
      include ::Packages::CleanupArtifactWorker

      MAX_CAPACITY = 2

      data_consistency :sticky

      queue_namespace :package_cleanup
      feature_category :package_registry

      idempotent!

      def max_running_jobs
        MAX_CAPACITY
      end

      private

      def model
        ::Packages::Helm::MetadataCache
      end

      def log_metadata(helm_metadata_cache)
        log_extra_metadata_on_done(:helm_metadata_cache_id, helm_metadata_cache.id)
      end

      def log_cleanup_item(helm_metadata_cache)
        logger.info(
          structured_payload(
            helm_metadata_cache_id: helm_metadata_cache.id
          )
        )
      end
    end
  end
end
