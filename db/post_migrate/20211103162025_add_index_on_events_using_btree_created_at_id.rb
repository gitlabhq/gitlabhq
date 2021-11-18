# frozen_string_literal: true

class AddIndexOnEventsUsingBtreeCreatedAtId < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_events_on_created_at_and_id'
  TABLE = :events
  COLUMNS = %i[created_at id]
  CONSTRAINTS = "created_at > '2021-08-27 00:00:00+00'"
  disable_ddl_transaction!

  def up
    add_concurrent_index TABLE, COLUMNS, name: INDEX_NAME, where: CONSTRAINTS
  end

  def down
    remove_concurrent_index TABLE, COLUMNS, name: INDEX_NAME, where: CONSTRAINTS
  end
end
