# frozen_string_literal: true

class CleanUpRenameIterationsCadencesLastRunDateToNextRunDate < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :iterations_cadences, :last_run_date, :next_run_date
  end

  def down
    undo_cleanup_concurrent_column_rename :iterations_cadences, :last_run_date, :next_run_date
  end
end
