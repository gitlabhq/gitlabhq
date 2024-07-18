# frozen_string_literal: true

class RequeueBackfillPartitionIdCiDailyBuildGroupReportResult < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = 'BackfillPartitionIdCiDailyBuildGroupReportResult'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 5000
  SUB_BATCH_SIZE = 200

  def up
    delete_batched_background_migration(MIGRATION, :ci_daily_build_group_report_results, :id, [])

    queue_batched_background_migration(
      MIGRATION,
      :ci_daily_build_group_report_results,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :ci_daily_build_group_report_results, :id, [])
  end
end
