# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDependencyProxyBlobStatesGroupId < BackfillDesiredShardingKeyJob
      operation_name :backfill_dependency_proxy_blob_states_group_id
      feature_category :geo_replication
    end
  end
end
