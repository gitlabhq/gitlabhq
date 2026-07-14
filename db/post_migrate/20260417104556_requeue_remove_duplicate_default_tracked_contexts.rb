# frozen_string_literal: true

class RequeueRemoveDuplicateDefaultTrackedContexts < Gitlab::Database::Migration[2.3]
  milestone '19.0'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "RemoveDuplicateDefaultTrackedContexts"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 20

  def up
    # no-op
  end

  def down
    # no-op
  end
end
