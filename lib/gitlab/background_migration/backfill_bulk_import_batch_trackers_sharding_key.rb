# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillBulkImportBatchTrackersShardingKey < BatchedMigrationJob
      operation_name :backfill_bulk_import_batch_trackers_sharding_key
      feature_category :importers

      def perform
        each_sub_batch do |sub_batch|
          start_id = sub_batch.minimum(:id)
          end_id = sub_batch.maximum(:id)

          connection.execute(<<~SQL)
            UPDATE bulk_import_batch_trackers
            SET
              organization_id = bulk_import_trackers.organization_id,
              namespace_id = bulk_import_trackers.namespace_id,
              project_id = bulk_import_trackers.project_id
            FROM bulk_import_trackers
            WHERE bulk_import_batch_trackers.tracker_id = bulk_import_trackers.id
                  AND bulk_import_batch_trackers.id BETWEEN #{start_id} AND #{end_id}
                  AND num_nonnulls(
                    bulk_import_batch_trackers.organization_id,
                    bulk_import_batch_trackers.namespace_id,
                    bulk_import_batch_trackers.project_id
                  ) != 1;
          SQL
        end
      end
    end
  end
end
