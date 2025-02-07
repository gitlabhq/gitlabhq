# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillBulkImportExportBatchesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_bulk_import_export_batches_project_id
      feature_category :importers
    end
  end
end
