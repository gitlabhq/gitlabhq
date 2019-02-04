class AddIndexToStagesPosition < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_stages, [:pipeline_id, :position]
  end

  def down
    remove_concurrent_index :ci_stages, [:pipeline_id, :position]
  end
end
