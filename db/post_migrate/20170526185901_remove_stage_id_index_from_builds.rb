class RemoveStageIdIndexFromBuilds < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    if index_exists?(:ci_builds, :stage_id)
      remove_foreign_key(:ci_builds, column: :stage_id)
      remove_concurrent_index(:ci_builds, :stage_id)
    end
  end

  def down
    # noop
  end
end
