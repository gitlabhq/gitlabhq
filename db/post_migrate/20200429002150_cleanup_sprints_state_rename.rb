# frozen_string_literal: true

class CleanupSprintsStateRename < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :sprints, :state, :state_enum
  end

  def down
    undo_cleanup_concurrent_column_rename :sprints, :state, :state_enum
  end
end
