# frozen_string_literal: true

class AddIssueCustomerRelationsContactsNamespaceIdNotNull < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :issue_customer_relations_contacts, :namespace_id
  end

  def down
    remove_not_null_constraint :issue_customer_relations_contacts, :namespace_id
  end
end
