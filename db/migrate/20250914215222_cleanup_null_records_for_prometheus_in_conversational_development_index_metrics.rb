# frozen_string_literal: true

class CleanupNullRecordsForPrometheusInConversationalDevelopmentIndexMetrics < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '18.5'

  BATCH_SIZE = 1000

  class Metric < MigrationRecord
    include EachBatch

    self.table_name = 'conversational_development_index_metrics'
  end

  def up
    # no-op - this migration is required to allow a rollback of
    # RemoveNotNullForPrometheusInConversationalDevelopmentIndexMetrics
  end

  def down
    Metric.each_batch(of: BATCH_SIZE) do |relation|
      relation.where(leader_projects_prometheus_active: nil)
        .update_all(leader_projects_prometheus_active: 0.0)

      relation.where(instance_projects_prometheus_active: nil)
        .update_all(instance_projects_prometheus_active: 0.0)
    end
  end
end
