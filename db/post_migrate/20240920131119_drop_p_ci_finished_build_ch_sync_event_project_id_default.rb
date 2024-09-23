# frozen_string_literal: true

class DropPCiFinishedBuildChSyncEventProjectIdDefault < Gitlab::Database::Migration[2.2]
  enable_lock_retries!

  milestone '17.5'

  TABLE_NAME = :p_ci_finished_build_ch_sync_events
  COLUMN_NAME = :project_id

  def up
    remove_column_default(TABLE_NAME, COLUMN_NAME)
  end

  def down
    change_column_default(TABLE_NAME, COLUMN_NAME, from: nil, to: -1)
  end
end
