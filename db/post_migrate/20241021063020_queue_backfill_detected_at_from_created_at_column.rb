# frozen_string_literal: true

class QueueBackfillDetectedAtFromCreatedAtColumn < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  MIGRATION = "BackfillDetectedAtFromCreatedAtColumn"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    # No-op because application logic bypassed default database-level value
    # Fixed with https://gitlab.com/gitlab-org/gitlab/-/merge_requests/180582
  end

  def down
    # No-op because application logic bypassed default database-level value
    # Fixed with https://gitlab.com/gitlab-org/gitlab/-/merge_requests/180582
  end
end
