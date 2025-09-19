# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillBulkImportTrackersShardingKey < BatchedMigrationJob
      operation_name :backfill_bulk_import_trackers_sharding_key
      feature_category :importers

      def perform
        each_sub_batch do |sub_batch|
          # Updating the row executes the 'trigger_bulk_import_trackers_sharding_key' which updates the sharding key.
          # So we just update `updated_at` and let the trigger figure out the correct value.
          sub_batch
            .where('num_nonnulls(namespace_id, organization_id, project_id) != 1')
            .update_all('updated_at = updated_at')
        end
      end
    end
  end
end
