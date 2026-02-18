# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MarkVirtualRegistriesPackagesMavenCacheEntriesPendingDestruction < BatchedMigrationJob
      cursor :upstream_id, :relative_path, :status

      operation_name :mark_virtual_registries_packages_maven_cache_entries_pending_destruction
      feature_category :virtual_registry

      PENDING_DESTRUCTION_STATUS = 2

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.update_all(status: PENDING_DESTRUCTION_STATUS)
        end
      end
    end
  end
end
