# frozen_string_literal: true

class AddAuthorIndexToDesignManagementVersions < Gitlab::Database::Migration[1.0]
  TABLE = :design_management_versions
  INDEX_NAME = 'index_design_management_versions_on_author_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index TABLE, :author_id, where: 'author_id IS NOT NULL', name: INDEX_NAME
  end

  def down
    remove_concurrent_index TABLE, :author_id, name: INDEX_NAME
  end
end
