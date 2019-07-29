# frozen_string_literal: true

class RemoveShaIndexFromVersions < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index :design_management_versions, :sha
  end

  def down
    add_concurrent_index :design_management_versions, :sha, unique: true, using: :btree
  end
end
