# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillBulkImportConfigurationsOrganizationId < BackfillDesiredShardingKeyJob
      operation_name :backfill_bulk_import_configurations_organization_id
      feature_category :importers
    end
  end
end
