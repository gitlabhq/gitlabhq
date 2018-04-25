class AddTmpStagePriorityIndexToCiBuilds < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:ci_builds, [:stage_id, :stage_idx],
                         where: 'stage_idx IS NOT NULL', name: 'tmp_build_stage_priority_index')
  end

  def down
    remove_concurrent_index_by_name(:ci_builds, 'tmp_build_stage_priority_index')
  end
end
