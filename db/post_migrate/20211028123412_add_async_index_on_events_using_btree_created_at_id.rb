# frozen_string_literal: true

class AddAsyncIndexOnEventsUsingBtreeCreatedAtId < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_events_on_created_at_and_id'
  TABLE = :events
  COLUMNS = %i[created_at id]
  CONSTRAINTS = "created_at > '2021-08-27'"

  def up
    prepare_async_index TABLE, COLUMNS, name: INDEX_NAME, where: CONSTRAINTS
  end

  def down
    unprepare_async_index TABLE, COLUMNS, name: INDEX_NAME, where: CONSTRAINTS
  end
end
