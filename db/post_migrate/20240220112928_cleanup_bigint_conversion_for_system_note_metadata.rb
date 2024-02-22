# frozen_string_literal: true

class CleanupBigintConversionForSystemNoteMetadata < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '16.10'

  TABLE = :system_note_metadata

  def up
    cleanup_conversion_of_integer_to_bigint(TABLE, :id)
  end

  def down
    restore_conversion_of_integer_to_bigint(TABLE, :id)
  end
end
