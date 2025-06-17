# frozen_string_literal: true

class DropPartialUniqueIndexOnIssuableResourceLinks < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_unique_issuable_resource_links_on_unique_issue_link'

  disable_ddl_transaction!

  milestone '18.1'

  def up
    remove_concurrent_index_by_name(:issuable_resource_links, INDEX_NAME)
  end

  def down
    add_concurrent_index(
      :issuable_resource_links,
      %i[issue_id link],
      where: "is_unique",
      unique: true,
      name: INDEX_NAME
    )
  end
end
