# frozen_string_literal: true

class PopulateSecurityOrchestrationPolicyConfigurationId < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 500
  MERGE_REQUEST_MIGRATION = 'PopulateApprovalMergeRequestRulesWithSecurityOrchestration'
  PROJECT_MIGRATION = 'PopulateApprovalProjectRulesWithSecurityOrchestration'
  INTERVAL = 2.minutes

  def up
    return unless Gitlab.ee?

    queue_batched_background_migration(
      PROJECT_MIGRATION,
      :approval_project_rules,
      :id,
      job_interval: INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )

    queue_batched_background_migration(
      MERGE_REQUEST_MIGRATION,
      :approval_merge_request_rules,
      :id,
      job_interval: INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(PROJECT_MIGRATION, :approval_project_rules, :id, [])
    delete_batched_background_migration(MERGE_REQUEST_MIGRATION, :approval_merge_request_rules, :id, [])
  end
end
