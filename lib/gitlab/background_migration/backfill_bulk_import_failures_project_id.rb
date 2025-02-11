# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillBulkImportFailuresProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_bulk_import_failures_project_id
      feature_category :importers
    end
  end
end
