# frozen_string_literal: true

class RemoveBackgroundOperationWorkersCellLocalNextMinCursorColumn < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  TABLE_NAME = :background_operation_workers_cell_local
  COLUMN_NAME = :next_min_cursor

  def up
    remove_column(TABLE_NAME, COLUMN_NAME)
  end

  def down
    add_column(TABLE_NAME, COLUMN_NAME, :jsonb)
  end
end
