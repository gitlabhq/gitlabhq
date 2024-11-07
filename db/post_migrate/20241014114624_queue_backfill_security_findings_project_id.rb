# frozen_string_literal: true

class QueueBackfillSecurityFindingsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  MIGRATION = "BackfillSecurityFindingsProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    # no-op because there was a bug in the original migration, which has been
    # fixed by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171503
  end

  def down
    # no-op because there was a bug in the original migration, which has been
    # fixed by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171503
  end
end
