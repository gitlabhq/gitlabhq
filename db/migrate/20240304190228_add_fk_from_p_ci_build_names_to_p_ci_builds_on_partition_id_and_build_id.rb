# frozen_string_literal: true

class AddFkFromPCiBuildNamesToPCiBuildsOnPartitionIdAndBuildId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '16.11'

  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :p_ci_build_names
  TARGET_TABLE_NAME = :p_ci_builds
  FK_NAME = :fk_rails_bc221a297a

  def up
    add_concurrent_partitioned_foreign_key(
      :p_ci_build_names, :p_ci_builds,
      column: [:partition_id, :build_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      reverse_lock_order: true,
      name: FK_NAME
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(
        SOURCE_TABLE_NAME,
        TARGET_TABLE_NAME,
        name: FK_NAME,
        reverse_lock_order: true
      )
    end
  end
end
