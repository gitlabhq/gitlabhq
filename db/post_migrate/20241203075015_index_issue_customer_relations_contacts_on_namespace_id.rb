# frozen_string_literal: true

class IndexIssueCustomerRelationsContactsOnNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  disable_ddl_transaction!

  INDEX_NAME = 'index_issue_customer_relations_contacts_on_namespace_id'

  def up
    add_concurrent_index :issue_customer_relations_contacts, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :issue_customer_relations_contacts, INDEX_NAME
  end
end
