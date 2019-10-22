# frozen_string_literal: true

class AddAuthorIndexToDesignManagementVersions < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :design_management_versions, :author_id, where: 'author_id IS NOT NULL'
  end

  def down
    remove_concurrent_index :design_management_versions, :author_id
  end
end
