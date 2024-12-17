# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillBulkImportExportUploadsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_bulk_import_export_uploads_project_id
      feature_category :importers
    end
  end
end
