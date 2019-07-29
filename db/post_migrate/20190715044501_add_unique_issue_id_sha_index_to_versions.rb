# frozen_string_literal: true

class AddUniqueIssueIdShaIndexToVersions < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :design_management_versions, [:sha, :issue_id], unique: true, using: :btree
  end

  def down
    remove_concurrent_index :design_management_versions, [:sha, :issue_id]
  end
end
