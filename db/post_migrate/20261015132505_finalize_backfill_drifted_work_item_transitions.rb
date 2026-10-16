# frozen_string_literal: true

class FinalizeBackfillDriftedWorkItemTransitions < Gitlab::Database::Migration[2.3]
  milestone '19.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = 'BackfillDriftedWorkItemTransitions'

  # GitLab.com is the only instance where the backfill was queued, see 20261006140000.
  def up
    return unless Gitlab.com_except_jh?

    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :work_item_transitions,
      column_name: :work_item_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
