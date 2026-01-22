# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillClusterPlatformsKubernetesShardingKey < BatchedMigrationJob
      operation_name :backfill_cluster_platforms_kubernetes_sharding_key
      feature_category :deployment_management

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(<<~SQL)
            UPDATE cluster_platforms_kubernetes
            SET
              organization_id = clusters.organization_id,
              group_id = clusters.group_id,
              project_id = clusters.project_id
            FROM clusters
            WHERE cluster_platforms_kubernetes.cluster_id = clusters.id
                  AND cluster_platforms_kubernetes.id IN (#{sub_batch.select(:id).to_sql})
                  AND num_nonnulls(
                    cluster_platforms_kubernetes.organization_id,
                    cluster_platforms_kubernetes.group_id,
                    cluster_platforms_kubernetes.project_id
                  ) != 1;
          SQL
        end
      end
    end
  end
end
