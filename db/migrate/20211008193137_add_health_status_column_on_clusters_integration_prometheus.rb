# frozen_string_literal: true

class AddHealthStatusColumnOnClustersIntegrationPrometheus < Gitlab::Database::Migration[1.0]
  def change
    # For now, health checks will only run on monitor demo projects
    add_column :clusters_integration_prometheus, :health_status, :smallint, limit: 2, default: 0, null: false
  end
end
