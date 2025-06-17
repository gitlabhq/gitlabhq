# frozen_string_literal: true

class DropForeignKeyForCiTriggerRequests < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :ci_trigger_requests
  TARGET_TABLE_NAME = :ci_triggers
  COLUMN_NAME = :trigger_id

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(
        SOURCE_TABLE_NAME,
        TARGET_TABLE_NAME,
        column: COLUMN_NAME,
        reverse_lock_order: true
      )
    end
  end

  def down
    add_concurrent_foreign_key(
      SOURCE_TABLE_NAME,
      TARGET_TABLE_NAME,
      column: COLUMN_NAME,
      target_column: :id,
      on_delete: :cascade,
      on_update: nil,
      validate: true,
      reverse_lock_order: true
    )
  end
end
