# frozen_string_literal: true

class BackfillAwardEmojiAwardableIdForBigintConversion < Gitlab::Database::Migration[2.1]
  TABLE = :award_emoji
  COLUMNS = %i[awardable_id]

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    revert_backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
