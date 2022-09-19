# frozen_string_literal: true

class RenameIterationsCadencesLastRunDateToNextRunDate < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    rename_column_concurrently :iterations_cadences, :last_run_date, :next_run_date
  end

  def down
    undo_rename_column_concurrently :iterations_cadences, :last_run_date, :next_run_date
  end
end
