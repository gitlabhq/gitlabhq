# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDependencyProxyManifestStatesGroupId < BackfillDesiredShardingKeyJob
      operation_name :backfill_dependency_proxy_manifest_states_group_id
      feature_category :geo_replication
    end
  end
end
