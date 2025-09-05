# frozen_string_literal: true

class QueueBackfillWorkspaceAgentkStates < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillWorkspaceAgentkStates"
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100
  DELAY_INTERVAL = 2.minutes

  # @return [Void]
  def up
    # no-op -- The migration logic has some bug. This change is done to prevent the deployed migration to run.
    nil
  end

  # @return [Void]
  def down
    # no-op
    nil
  end
end
