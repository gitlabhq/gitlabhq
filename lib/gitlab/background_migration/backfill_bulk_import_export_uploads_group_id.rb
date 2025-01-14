# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillBulkImportExportUploadsGroupId < BackfillDesiredShardingKeyJob
      operation_name :backfill_bulk_import_export_uploads_group_id
      feature_category :importers
    end
  end
end
