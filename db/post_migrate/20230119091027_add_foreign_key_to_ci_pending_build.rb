# frozen_string_literal: true

class AddForeignKeyToCiPendingBuild < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :ci_pending_builds
  TARGET_TABLE_NAME = :ci_builds
  COLUMN = :build_id
  TARGET_COLUMN = :id
  FK_NAME = :fk_rails_725a2644a3_p
  PARTITION_COLUMN = :partition_id

  def up
    add_concurrent_foreign_key(
      SOURCE_TABLE_NAME,
      TARGET_TABLE_NAME,
      column: [PARTITION_COLUMN, COLUMN],
      target_column: [PARTITION_COLUMN, TARGET_COLUMN],
      validate: true,
      reverse_lock_order: true,
      name: FK_NAME,
      on_update: :cascade
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(SOURCE_TABLE_NAME, name: FK_NAME)
    end
  end
end
