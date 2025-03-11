# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDeploymentMergeRequestsProjectId < BatchedMigrationJob
      operation_name :backfill_deployment_merge_requests_project_id
      feature_category :continuous_delivery
      cursor :deployment_id, :merge_request_id

      def perform
        each_sub_batch do |relation|
          connection.execute(<<~SQL)
            WITH batched_relation AS (
              #{relation.where(project_id: nil).select(:deployment_id, :merge_request_id).to_sql}
            )
            UPDATE deployment_merge_requests
            SET project_id = deployments.project_id
            FROM batched_relation
            INNER JOIN deployments ON batched_relation.deployment_id = deployments.id
            WHERE deployment_merge_requests.deployment_id = batched_relation.deployment_id
              AND deployment_merge_requests.merge_request_id = batched_relation.merge_request_id;
          SQL
        end
      end
    end
  end
end
