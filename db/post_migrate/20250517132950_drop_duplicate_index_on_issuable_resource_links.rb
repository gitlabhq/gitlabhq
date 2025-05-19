# frozen_string_literal: true

class DropDuplicateIndexOnIssuableResourceLinks < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_issuable_resource_links_on_issue_id'

  disable_ddl_transaction!

  milestone '18.1'

  def up
    remove_concurrent_index_by_name(:issuable_resource_links, INDEX_NAME)
  end

  def down
    add_concurrent_index(
      :issuable_resource_links,
      :issue_id,
      name: INDEX_NAME
    )
  end
end
