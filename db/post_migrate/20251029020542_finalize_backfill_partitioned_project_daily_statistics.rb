# frozen_string_literal: true

class FinalizeBackfillPartitionedProjectDailyStatistics < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillPartitionedProjectDailyStatistics',
      table_name: :project_daily_statistics,
      column_name: :id,
      job_arguments: ['project_daily_statistics_b8088ecbd2'],
      finalize: true
    )
  end

  def down; end
end
