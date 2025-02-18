# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDesignManagementRepositoryStatesNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_design_management_repository_states_namespace_id
      feature_category :geo_replication
    end
  end
end
