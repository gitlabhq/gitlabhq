# frozen_string_literal: true

class AddNamespaceIdToIssueCustomerRelationsContacts < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :issue_customer_relations_contacts, :namespace_id, :bigint
  end
end
