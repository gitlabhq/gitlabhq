class AddStageIdForeignKeyToBuilds < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless index_exists?(:ci_builds, :stage_id)
      add_concurrent_index(:ci_builds, :stage_id)
    end

    unless foreign_key_exists?(:ci_builds, :ci_stages, column: :stage_id)
      add_concurrent_foreign_key(:ci_builds, :ci_stages, column: :stage_id, on_delete: :cascade)
    end
  end

  def down
    if foreign_key_exists?(:ci_builds, column: :stage_id)
      remove_foreign_key(:ci_builds, column: :stage_id)
    end

    if index_exists?(:ci_builds, :stage_id)
      remove_concurrent_index(:ci_builds, :stage_id)
    end
  end
end
