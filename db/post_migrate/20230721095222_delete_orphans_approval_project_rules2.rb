# frozen_string_literal: true

class DeleteOrphansApprovalProjectRules2 < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  PROJECT_MIGRATION = 'DeleteOrphansApprovalProjectRules2'
  INTERVAL = 2.minutes

  def up
    queue_batched_background_migration(
      PROJECT_MIGRATION,
      :approval_project_rules,
      :id,
      job_interval: INTERVAL,
      batch_size: 500,
      sub_batch_size: 100
    )
  end

  def down
    delete_batched_background_migration(PROJECT_MIGRATION, :approval_project_rules, :id, [])
  end
end
