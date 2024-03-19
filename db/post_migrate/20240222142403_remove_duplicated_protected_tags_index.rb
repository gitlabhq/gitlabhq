# frozen_string_literal: true

class RemoveDuplicatedProtectedTagsIndex < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.10'

  INDEX_NAME = 'index_protected_tags_on_project_id'

  def up
    remove_concurrent_index_by_name :protected_tags, name: INDEX_NAME
  end

  def down
    add_concurrent_index :protected_tags, :project_id, name: INDEX_NAME
  end
end
