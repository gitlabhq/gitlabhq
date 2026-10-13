# frozen_string_literal: true

class RequeueMarkDoneFinalizedMergeRequestTodosAgain < Gitlab::Database::Migration[2.3]
  milestone '19.5'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "MarkDoneFinalizedMergeRequestTodos"
  BATCH_SIZE = 50_000
  SUB_BATCH_SIZE = 1_000

  def up
    delete_batched_background_migration(MIGRATION, :todos, :id, [])

    queue_batched_background_migration(
      MIGRATION,
      :todos,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :todos, :id, [])
  end
end
