# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillBulkImportTrackersNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_bulk_import_trackers_namespace_id
      feature_category :importers
    end
  end
end
