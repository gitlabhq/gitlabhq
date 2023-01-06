# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfills the `vulnerability_reads.casted_cluster_agent_id` column
    class BackfillClusterAgentsHasVulnerabilities < Gitlab::BackgroundMigration::BatchedMigrationJob
      VULNERABILITY_READS_JOIN = <<~SQL
        INNER JOIN vulnerability_reads
        ON vulnerability_reads.casted_cluster_agent_id = cluster_agents.id AND
        vulnerability_reads.project_id = cluster_agents.project_id AND
        vulnerability_reads.report_type = 7
      SQL

      RELATION = ->(relation) do
        relation
          .where(has_vulnerabilities: false)
      end

      operation_name :update_all
      feature_category :database

      def perform
        each_sub_batch(batching_scope: RELATION) do |sub_batch|
          sub_batch
            .joins(VULNERABILITY_READS_JOIN)
            .update_all(has_vulnerabilities: true)
        end
      end
    end
  end
end
