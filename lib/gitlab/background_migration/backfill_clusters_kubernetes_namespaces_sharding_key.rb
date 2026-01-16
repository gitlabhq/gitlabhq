# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillClustersKubernetesNamespacesShardingKey < BatchedMigrationJob
      operation_name :backfill_clusters_kubernetes_namespaces_sharding_key
      feature_category :deployment_management

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(<<~SQL)
            UPDATE clusters_kubernetes_namespaces
            SET
              organization_id = clusters.organization_id,
              group_id = clusters.group_id,
              sharding_project_id = clusters.project_id
            FROM clusters
            WHERE clusters_kubernetes_namespaces.cluster_id = clusters.id
                  AND clusters_kubernetes_namespaces.id IN (#{sub_batch.select(:id).to_sql})
                  AND num_nonnulls(
                    clusters_kubernetes_namespaces.organization_id,
                    clusters_kubernetes_namespaces.group_id,
                    clusters_kubernetes_namespaces.sharding_project_id
                  ) != 1;
          SQL
        end
      end
    end
  end
end
