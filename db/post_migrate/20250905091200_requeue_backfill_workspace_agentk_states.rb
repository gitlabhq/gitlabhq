# frozen_string_literal: true

class RequeueBackfillWorkspaceAgentkStates < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillWorkspaceAgentkStates"
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100
  DELAY_INTERVAL = 2.minutes

  # @return [Void]
  def up
    queue_batched_background_migration(
      MIGRATION,
      :workspaces,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      job_interval: DELAY_INTERVAL
    )
    nil
  end

  # @return [Void]
  def down
    delete_batched_background_migration(MIGRATION, :workspaces, :id, [])
    nil
  end
end
