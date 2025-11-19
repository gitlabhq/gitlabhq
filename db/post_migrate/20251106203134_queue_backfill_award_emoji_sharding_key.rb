# frozen_string_literal: true

class QueueBackfillAwardEmojiShardingKey < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillAwardEmojiShardingKey"
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :award_emoji,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :award_emoji, :id, [])
  end
end
