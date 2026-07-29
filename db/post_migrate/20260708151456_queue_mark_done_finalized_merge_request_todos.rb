# frozen_string_literal: true

class QueueMarkDoneFinalizedMergeRequestTodos < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  MIGRATION = "MarkDoneFinalizedMergeRequestTodos"

  # No-op: the original batch sizes (BATCH_SIZE 50_000 / SUB_BATCH_SIZE 5_000)
  # caused statement timeouts on GitLab.com, so this migration is re-queued with
  # smaller batches in RequeueMarkDoneFinalizedMergeRequestTodos. Kept as a no-op
  # so instances upgrading across multiple patch releases do not create, delete,
  # then recreate the batched background migration.
  def up; end

  def down; end
end
