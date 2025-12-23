# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDeploymentClustersProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_deployment_clusters_project_id
      feature_category :deployment_management
    end
  end
end
