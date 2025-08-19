# frozen_string_literal: true

class QueueResetAutoDuoCodeReviewFalseValues < Gitlab::Database::Migration[2.3]
  milestone '18.3'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "ResetAutoDuoCodeReviewFalseValues"
  BATCH_SIZE = 50_000
  SUB_BATCH_SIZE = 5_000

  def up
    queue_batched_background_migration(
      MIGRATION,
      :project_settings,
      :project_id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :project_settings, :project_id, [])
  end
end
