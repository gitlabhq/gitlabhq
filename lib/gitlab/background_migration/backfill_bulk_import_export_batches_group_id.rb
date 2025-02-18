# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillBulkImportExportBatchesGroupId < BackfillDesiredShardingKeyJob
      operation_name :backfill_bulk_import_export_batches_group_id
      feature_category :importers
    end
  end
end
