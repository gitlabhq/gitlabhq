# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MarkPackagesHelmMetadataCachesPendingDestruction < BatchedMigrationJob
      feature_category :package_registry
      operation_name :mark_packages_helm_metadata_caches_pending_destruction

      PENDING_DESTRUCTION_STATUS = 2

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.update_all(status: PENDING_DESTRUCTION_STATUS)
        end
      end
    end
  end
end
