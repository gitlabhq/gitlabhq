class AddIndexToNamespaceMetrics < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    add_concurrent_index :namespace_metrics, [:namespace_id], { unique: true }
  end
end
