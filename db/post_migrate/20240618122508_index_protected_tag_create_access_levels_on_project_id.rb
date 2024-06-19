# frozen_string_literal: true

class IndexProtectedTagCreateAccessLevelsOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  INDEX_NAME = 'index_protected_tag_create_access_levels_on_project_id'

  def up
    add_concurrent_index :protected_tag_create_access_levels, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :protected_tag_create_access_levels, INDEX_NAME
  end
end
