# frozen_string_literal: true

class FinalizeBackfillPartitionWebHookLogDaily < Gitlab::Database::Migration[2.2]
  milestone '18.0'
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    return if should_not_run?

    # rubocop:disable Migration/BatchMigrationsPostOnly -- Must be run before we switch to new table
    # Does not run on .com
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillPartitionedWebHookLogsDaily',
      table_name: :web_hook_logs,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
    # rubocop:enable Migration/BatchMigrationsPostOnly
  end

  def down
    # no-op
  end

  private

  def should_not_run?
    Gitlab.com_except_jh?
  end
end
