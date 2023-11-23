# frozen_string_literal: true

class QueueBackfillFindingIdInVulnerabilities < Gitlab::Database::Migration[2.1]
  MIGRATION = "BackfillFindingIdInVulnerabilities"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  # marking no-op
  # per https://docs.gitlab.com/ee/development/database/batched_background_migrations.html#requeuing-batched-background-migrations
  def up; end

  def down; end
end
