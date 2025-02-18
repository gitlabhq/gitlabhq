# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDesignManagementDesignsVersionsNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_design_management_designs_versions_namespace_id
      feature_category :design_management
    end
  end
end
