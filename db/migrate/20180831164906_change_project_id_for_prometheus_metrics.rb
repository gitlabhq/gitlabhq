class ChangeProjectIdForPrometheusMetrics < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    change_column_null :prometheus_metrics, :project_id, true
  end
end
