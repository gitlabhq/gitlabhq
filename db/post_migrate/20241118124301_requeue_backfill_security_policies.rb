# frozen_string_literal: true

class RequeueBackfillSecurityPolicies < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillSecurityPolicies"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 100
  SUB_BATCH_SIZE = 10

  def up
    delete_batched_background_migration(MIGRATION, :security_orchestration_policy_configurations, :id, [])

    queue_batched_background_migration(
      MIGRATION,
      :security_orchestration_policy_configurations,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :security_orchestration_policy_configurations, :id, [])
  end
end
