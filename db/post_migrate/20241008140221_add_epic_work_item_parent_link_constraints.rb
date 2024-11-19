# frozen_string_literal: true

class AddEpicWorkItemParentLinkConstraints < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  disable_ddl_transaction!
  INDEX_NAME = 'index_unique_parent_link_id_on_epics'

  def up
    add_concurrent_index :epics, :work_item_parent_link_id, unique: true, name: INDEX_NAME
    add_concurrent_foreign_key(:epics, :work_item_parent_links,
      column: :work_item_parent_link_id, validate: true, on_delete: :nullify
    )
  end

  def down
    remove_concurrent_index_by_name :epics, INDEX_NAME
    remove_foreign_key_if_exists :epics, column: :work_item_parent_link_id
  end
end
