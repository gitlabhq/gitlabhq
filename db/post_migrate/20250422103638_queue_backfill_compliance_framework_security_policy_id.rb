# frozen_string_literal: true

class QueueBackfillComplianceFrameworkSecurityPolicyId < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillComplianceFrameworkSecurityPolicyId"
  BATCH_SIZE = 200
  SUB_BATCH_SIZE = 20
  DELAY_INTERVAL = 2.minutes

  def up
    queue_batched_background_migration(
      MIGRATION,
      :compliance_framework_security_policies,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      job_interval: DELAY_INTERVAL
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :compliance_framework_security_policies, :id, [])
  end
end
