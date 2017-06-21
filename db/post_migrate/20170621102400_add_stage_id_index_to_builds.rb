class AddStageIdIndexToBuilds < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless index_exists?(:ci_builds, :stage_id)
      add_concurrent_index(:ci_builds, :stage_id)
    end
  end

  def down
    if index_exists?(:ci_builds, :stage_id)
      remove_concurrent_index(:ci_builds, :stage_id)
    end
  end
end
