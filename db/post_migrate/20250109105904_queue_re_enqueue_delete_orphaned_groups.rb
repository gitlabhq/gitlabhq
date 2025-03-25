# frozen_string_literal: true

class QueueReEnqueueDeleteOrphanedGroups < Gitlab::Database::Migration[2.2]
  milestone '17.8'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "DeleteOrphanedGroups"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    # no-op because this migration will be re-queued to attempt fixing
    # records missed by the previous run or resurface the error logs.
  end

  def down
    # no-op because this migration will be re-queued to attempt fixing
    # records missed by the previous run or resurface the error logs.
  end
end
