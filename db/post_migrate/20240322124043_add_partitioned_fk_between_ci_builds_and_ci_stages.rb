# frozen_string_literal: true

class AddPartitionedFkBetweenCiBuildsAndCiStages < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  milestone '16.11'
  disable_ddl_transaction!

  TABLE_NAME = :p_ci_builds
  REFERENCED_TABLE = :p_ci_stages
  FK_NAME = :tmp_fk_3a9eaa254d_p

  def up
    add_concurrent_partitioned_foreign_key(
      TABLE_NAME,
      REFERENCED_TABLE,
      name: FK_NAME,
      column: [:partition_id, :stage_id],
      target_column: [:partition_id, :id],
      on_delete: :cascade,
      on_update: :cascade,
      validate: true,
      reverse_lock_order: true
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(
        TABLE_NAME,
        REFERENCED_TABLE,
        name: FK_NAME,
        reverse_lock_order: true
      )
    end

    add_concurrent_partitioned_foreign_key(
      TABLE_NAME,
      REFERENCED_TABLE,
      name: FK_NAME,
      column: [:partition_id, :stage_id],
      target_column: [:partition_id, :id],
      on_delete: :cascade,
      on_update: :cascade,
      validate: false,
      reverse_lock_order: true
    )
  end
end
