# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Migration/BackgroundMigrationBaseClass -- BackfillDesiredShardingKeyJob inherits from BatchedMigrationJob.
    class BackfillDesignManagementDesignsNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_design_management_designs_namespace_id
      feature_category :design_management
    end
    # rubocop: enable Migration/BackgroundMigrationBaseClass
  end
end
