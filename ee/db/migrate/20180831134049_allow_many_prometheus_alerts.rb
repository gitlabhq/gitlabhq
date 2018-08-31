class AllowManyPrometheusAlerts < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :prometheus_alerts, [:project_id, :prometheus_metric_id], unique: true
    remove_concurrent_index :prometheus_alerts, :prometheus_metric_id, unique: true
  end

  def down
    add_concurrent_index :prometheus_alerts, :prometheus_metric_id, unique: true
    remove_concurrent_index :prometheus_alerts, [:project_id, :prometheus_metric_id], unique: true
  end
end
