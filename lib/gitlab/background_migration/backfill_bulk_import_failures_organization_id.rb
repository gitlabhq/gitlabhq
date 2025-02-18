# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillBulkImportFailuresOrganizationId < BackfillDesiredShardingKeyJob
      operation_name :backfill_bulk_import_failures_organization_id
      feature_category :importers
    end
  end
end
