class AddIndexConstraintsToPipelineIid < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_pipelines, [:project_id, :iid], unique: true, where: 'iid IS NOT NULL'
  end

  def down
    remove_concurrent_index :ci_pipelines, [:project_id, :iid]
  end
end
