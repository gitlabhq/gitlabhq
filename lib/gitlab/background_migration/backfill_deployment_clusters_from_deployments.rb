# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfill deployment_clusters for a range of deployments
    class BackfillDeploymentClustersFromDeployments
      def perform(start_id, end_id)
        ActiveRecord::Base.connection.execute <<~SQL
          INSERT INTO deployment_clusters (deployment_id, cluster_id)
            SELECT deployments.id, deployments.cluster_id
            FROM deployments
            WHERE deployments.cluster_id IS NOT NULL
              AND deployments.id BETWEEN #{start_id} AND #{end_id}
            ON CONFLICT DO NOTHING
        SQL
      end
    end
  end
end
