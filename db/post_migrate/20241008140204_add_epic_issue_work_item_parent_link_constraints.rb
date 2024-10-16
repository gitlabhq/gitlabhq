# frozen_string_literal: true

class AddEpicIssueWorkItemParentLinkConstraints < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  disable_ddl_transaction!
  INDEX_NAME = 'index_unique_parent_link_id_on_epic_issues'

  def up
    add_concurrent_index :epic_issues, :work_item_parent_link_id, unique: true, name: INDEX_NAME
    add_concurrent_foreign_key(:epic_issues, :work_item_parent_links,
      column: :work_item_parent_link_id, validate: true, on_delete: :cascade
    )
  end

  def down
    remove_concurrent_index_by_name :epic_issues, INDEX_NAME
    remove_foreign_key_if_exists :epic_issues, column: :work_item_parent_link_id
  end
end
