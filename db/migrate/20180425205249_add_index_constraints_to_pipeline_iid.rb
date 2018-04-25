class AddIndexConstraintsToPipelineIid < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_pipelines, [:project_id, :iid_per_project], unique: true, where: 'iid_per_project IS NOT NULL'
  end

  def down
    remove_concurrent_index :ci_pipelines, [:project_id, :iid_per_project]
  end
end
