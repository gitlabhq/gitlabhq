# frozen_string_literal: true

class RequeueBackfillPushEventPayloadsProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.3'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillPushEventPayloadsProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    # This is a no-op to prevent it from running because this migration is causing timeouts: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198522#note_2650827634
  end

  def down
    # This is a no-op to prevent it from running because this migration is causing timeouts: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198522#note_2650827634
  end
end
