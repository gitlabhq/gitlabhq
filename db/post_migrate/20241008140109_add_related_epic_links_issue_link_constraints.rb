# frozen_string_literal: true

class AddRelatedEpicLinksIssueLinkConstraints < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  disable_ddl_transaction!
  INDEX_NAME = 'index_unique_issue_link_id_on_related_epic_links'

  def up
    add_concurrent_index :related_epic_links, :issue_link_id, unique: true, name: INDEX_NAME
    add_concurrent_foreign_key(:related_epic_links, :issue_links,
      column: :issue_link_id, validate: true, on_delete: :cascade
    )
  end

  def down
    remove_concurrent_index_by_name :related_epic_links, INDEX_NAME
    remove_foreign_key_if_exists :related_epic_links, column: :issue_link_id
  end
end
