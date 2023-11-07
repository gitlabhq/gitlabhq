# frozen_string_literal: true

class InitializeConversionOfSystemNoteMetadataToBigint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  TABLE = :system_note_metadata
  COLUMNS = %i[id]

  milestone '16.6'

  def up
    initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    revert_initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
