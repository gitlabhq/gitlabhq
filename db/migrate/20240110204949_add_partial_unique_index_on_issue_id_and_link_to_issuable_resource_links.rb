# frozen_string_literal: true

class AddPartialUniqueIndexOnIssueIdAndLinkToIssuableResourceLinks < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.9'
  INDEX_NAME = 'index_unique_issuable_resource_links_on_unique_issue_link'

  def up
    add_concurrent_index :issuable_resource_links,
      %i[issue_id link],
      unique: true,
      where: "is_unique",
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :issuable_resource_links, INDEX_NAME
  end
end
