class AddIndexToProjectMetrics < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    add_concurrent_index :project_metrics, [:project_id], { unique: true }
  end
end
