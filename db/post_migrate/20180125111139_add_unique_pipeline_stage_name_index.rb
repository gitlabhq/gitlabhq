class AddUniquePipelineStageNameIndex < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index :ci_stages, [:pipeline_id, :name]
    add_concurrent_index :ci_stages, [:pipeline_id, :name], unique: true
  end

  def down
    remove_concurrent_index :ci_stages, [:pipeline_id, :name], unique: true
    add_concurrent_index :ci_stages, [:pipeline_id, :name]
  end
end
