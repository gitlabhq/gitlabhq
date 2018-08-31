class AddCommonToPrometheusMetrics < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:prometheus_metrics, :common, :boolean, default: false)
  end

  def down
    remove_column(:prometheus_metrics, :common)
  end
end
