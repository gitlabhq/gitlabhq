# frozen_string_literal: true

class IndexIssueLinksOnNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_issue_links_on_namespace_id'

  def up
    add_concurrent_index :issue_links, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :issue_links, INDEX_NAME
  end
end
