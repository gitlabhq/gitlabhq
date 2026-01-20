# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillClusterProvidersAwsShardingKey < BatchedMigrationJob
      operation_name :backfill_cluster_providers_aws_sharding_key
      feature_category :deployment_management

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(<<~SQL)
            UPDATE cluster_providers_aws
            SET
              organization_id = clusters.organization_id,
              group_id = clusters.group_id,
              project_id = clusters.project_id
            FROM clusters
            WHERE cluster_providers_aws.cluster_id = clusters.id
                  AND cluster_providers_aws.id IN (#{sub_batch.select(:id).to_sql})
                  AND num_nonnulls(
                    cluster_providers_aws.organization_id,
                    cluster_providers_aws.group_id,
                    cluster_providers_aws.project_id
                  ) != 1;
          SQL
        end
      end
    end
  end
end
