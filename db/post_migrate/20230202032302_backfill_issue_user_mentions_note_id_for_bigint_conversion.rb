# frozen_string_literal: true

class BackfillIssueUserMentionsNoteIdForBigintConversion < Gitlab::Database::Migration[2.1]
  TABLE = :issue_user_mentions
  COLUMNS = %i[note_id]

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS, batch_size: 40_000, sub_batch_size: 500)
  end

  def down
    revert_backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
