# frozen_string_literal: true

class LockVersionCleanupForIssues < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    validate_not_null_constraint :issues, :lock_version
    remove_concurrent_index_by_name :issues, name: 'index_issues_on_id'
  end

  def down
    add_concurrent_index :issues, :id, where: "lock_version IS NULL", name: 'index_issues_on_id'
  end
end
