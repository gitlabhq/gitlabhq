# frozen_string_literal: true

class FinalizeBackfillOrganizationIdKeys < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  # Milestone schedule:
  # * 18.7 - Backfill enqueued and completed in .com
  # * 18.8 - Required stop
  # * 18.9 - It is now safe to deploy this finalization

  milestone '18.9'
  disable_ddl_transaction!

  MIGRATION = 'BackfillOrganizationIdKeys'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :keys,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
