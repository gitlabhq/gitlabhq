# frozen_string_literal: true

class QueueBackfillDriftedWorkItemTransitions < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillDriftedWorkItemTransitions"
  BATCH_SIZE = 10_000
  # Each sub-batch reads one issues row per transitions row, so the cost scales with this value.
  # Measured on a production clone with a cold cache: 250 rows runs in ~440 ms, 500 in ~860 ms to
  # 1.0 s, which is too close to the 1 second per query guideline for background migrations.
  SUB_BATCH_SIZE = 250

  # Only GitLab.com ran the batch one swap before 20261005130000 rebound the trigger, so it is the
  # only instance where work_item_transitions can have drifted. Elsewhere the swap already recreates
  # the trigger as part of itself, and queueing here would read the whole table to update nothing.
  def up
    return unless Gitlab.com_except_jh?

    queue_batched_background_migration(
      MIGRATION,
      :work_item_transitions,
      :work_item_id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    return unless Gitlab.com_except_jh?

    delete_batched_background_migration(MIGRATION, :work_item_transitions, :work_item_id, [])
  end
end
