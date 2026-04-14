# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPackagesHelmMetadataCacheStatesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_packages_helm_metadata_cache_states_project_id
      feature_category :geo_replication
    end
  end
end
