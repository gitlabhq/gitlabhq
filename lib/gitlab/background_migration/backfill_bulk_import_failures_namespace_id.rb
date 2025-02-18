# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillBulkImportFailuresNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_bulk_import_failures_namespace_id
      feature_category :importers
    end
  end
end
