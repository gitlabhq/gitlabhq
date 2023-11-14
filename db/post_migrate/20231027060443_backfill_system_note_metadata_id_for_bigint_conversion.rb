# frozen_string_literal: true

class BackfillSystemNoteMetadataIdForBigintConversion < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  TABLE = :system_note_metadata
  COLUMNS = %i[id]

  milestone '16.6'

  def up
    backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS, sub_batch_size: 100)
  end

  def down
    revert_backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
