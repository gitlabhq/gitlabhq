# frozen_string_literal: true

class RenameEpicsStateToStateId < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    rename_column_concurrently :epics, :state, :state_id
  end

  def down
    cleanup_concurrent_column_rename :epics, :state_id, :state
  end
end
