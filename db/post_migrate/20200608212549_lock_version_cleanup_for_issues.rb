# frozen_string_literal: true

class LockVersionCleanupForIssues < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    validate_not_null_constraint :issues, :lock_version
    remove_concurrent_index :issues, :lock_version, where: "lock_version IS NULL"
  end

  def down
    add_concurrent_index :issues, :lock_version, where: "lock_version IS NULL"
  end
end
