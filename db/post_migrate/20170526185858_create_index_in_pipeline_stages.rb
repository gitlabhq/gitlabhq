class CreateIndexInPipelineStages < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:ci_stages, [:pipeline_id, :name])
  end

  def down
    remove_concurrent_index(:ci_stages, [:pipeline_id, :name])
  end
end
