# frozen_string_literal: true

class CreateTodosCoalescedSnoozedUntilCreatedAtIndex < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.9'

  TABLE_NAME = :todos
  INDEX_NAME = 'index_todos_coalesced_snoozed_until_created_at'

  def up
    add_concurrent_index TABLE_NAME, 'user_id, state, timestamp_coalesce(snoozed_until, created_at)', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, name: INDEX_NAME
  end
end
