# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillBulkImportTrackersOrganizationId < BackfillDesiredShardingKeyJob
      operation_name :backfill_bulk_import_trackers_organization_id
      feature_category :importers
    end
  end
end
