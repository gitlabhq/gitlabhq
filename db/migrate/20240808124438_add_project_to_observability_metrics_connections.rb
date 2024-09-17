# frozen_string_literal: true

class AddProjectToObservabilityMetricsConnections < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  disable_ddl_transaction!

  def up
    add_column :observability_metrics_issues_connections, :project_id, :bigint
    add_concurrent_index :observability_metrics_issues_connections, :project_id
  end

  def down
    remove_column :observability_metrics_issues_connections, :project_id
  end
end
