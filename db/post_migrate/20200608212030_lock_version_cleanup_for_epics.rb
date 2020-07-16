# frozen_string_literal: true

class LockVersionCleanupForEpics < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    validate_not_null_constraint :epics, :lock_version
    remove_concurrent_index :epics, :id, where: "lock_version IS NULL"
  end

  def down
    add_concurrent_index :epics, :id, where: "lock_version IS NULL"
  end
end
