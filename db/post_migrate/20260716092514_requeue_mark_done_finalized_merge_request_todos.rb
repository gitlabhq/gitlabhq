# frozen_string_literal: true

class RequeueMarkDoneFinalizedMergeRequestTodos < Gitlab::Database::Migration[2.3]
  milestone '19.3'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "MarkDoneFinalizedMergeRequestTodos"
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 250

  def up
    # The original run queued by QueueMarkDoneFinalizedMergeRequestTodos failed
    # on GitLab.com with statement timeouts under the larger batch sizes
    # (BATCH_SIZE 50_000 / SUB_BATCH_SIZE 5_000). Delete that run and re-queue
    # with smaller batches so each sub-batch statement completes within the
    # statement timeout.
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
