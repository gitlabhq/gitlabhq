# frozen_string_literal: true

module Packages
  module Nuget
    class CleanupStaleSymbolsWorker
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
        ::Packages::Nuget::Symbol
      end

      def next_item
        model.next_pending_destruction(order_by: nil)
      end

      def log_metadata(nuget_symbol)
        log_extra_metadata_on_done(:nuget_symbol_id, nuget_symbol.id)
      end

      def log_cleanup_item(nuget_symbol)
        logger.info(
          structured_payload(
            nuget_symbol_id: nuget_symbol.id
          )
        )
      end
    end
  end
end
