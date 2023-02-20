# frozen_string_literal: true

class InitializeConversionOfNoteDiffFilesDiffNoteIdToBigint < Gitlab::Database::Migration[2.1]
  TABLE = :note_diff_files
  COLUMNS = %i[diff_note_id]

  enable_lock_retries!

  def up
    initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    revert_initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
