# frozen_string_literal: true

class QueueBackfillMergeRequestCleanupSchedulesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillMergeRequestCleanupSchedulesProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    # no-op because the original migration failed
    #   fixed by: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198596
  end

  def down
    # no-op because the original migration failed
    #   fixed by: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198596
  end
end
