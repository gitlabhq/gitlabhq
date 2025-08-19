# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillClustersShardingKey < BatchedMigrationJob
      operation_name :backfill_clusters_sharding_key
      feature_category :deployment_management

      PROJECT_TYPE = 3
      GROUP_TYPE = 2
      INSTANCE_TYPE = 1

      DEFAULT_ORGANIZATION_ID = 1

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where(cluster_type: PROJECT_TYPE, project_id: nil)
            .where('cluster_projects.cluster_id = clusters.id')
            .update_all('project_id = cluster_projects.project_id FROM cluster_projects')

          sub_batch
            .where(cluster_type: GROUP_TYPE, group_id: nil)
            .where('cluster_groups.cluster_id = clusters.id')
            .update_all('group_id = cluster_groups.group_id FROM cluster_groups')

          sub_batch
            .where(cluster_type: INSTANCE_TYPE, organization_id: nil)
            .update_all(organization_id: DEFAULT_ORGANIZATION_ID)
        end
      end
    end
  end
end
