# frozen_string_literal: true

class CleanupEpicsStateIdRename < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :epics, :state, :state_id
  end

  def down
    rename_column_concurrently :epics, :state_id, :state
  end
end
