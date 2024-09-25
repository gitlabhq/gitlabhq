# frozen_string_literal: true

class QueueBackfillCiUnitTestFailuresProjectId < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_ci
  milestone '17.5'

  MIGRATION = "BackfillCiUnitTestFailuresProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :ci_unit_test_failures,
      :id,
      :project_id,
      :ci_unit_tests,
      :project_id,
      :unit_test_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :ci_unit_test_failures,
      :id,
      [
        :project_id,
        :ci_unit_tests,
        :project_id,
        :unit_test_id
      ]
    )
  end
end
