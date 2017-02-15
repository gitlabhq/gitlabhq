class AddTriggerIdIndex < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    add_concurrent_index :ci_commits, [:gl_project_id, :trigger_id]
  end
end
