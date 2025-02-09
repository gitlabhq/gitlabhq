# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillBulkImportTrackersProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_bulk_import_trackers_project_id
      feature_category :importers
    end
  end
end
