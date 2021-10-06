# frozen_string_literal: true

class AddIssueCustomerRelationsContactsForeignKeys < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :issue_customer_relations_contacts, :issues, column: :issue_id
    add_concurrent_foreign_key :issue_customer_relations_contacts, :customer_relations_contacts, column: :contact_id
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :issue_customer_relations_contacts, column: :issue_id
    end

    with_lock_retries do
      remove_foreign_key_if_exists :issue_customer_relations_contacts, column: :contact_id
    end
  end
end
