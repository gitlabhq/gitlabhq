# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillCatalogResourceVersionsReleasedAt < BatchedMigrationJob
      operation_name :backfill_catalog_resource_versions_released_at
      feature_category :pipeline_composition

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where('release_id = releases.id')
            .update_all('released_at = releases.released_at FROM releases')
        end
      end
    end
  end
end
