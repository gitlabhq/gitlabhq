class AddIndexToLabelsForTypeAndProject < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    add_concurrent_index :labels, [:type, :project_id]
  end
end
