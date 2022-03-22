# frozen_string_literal: true

class AddContactsIndexOnGroupEmailAndId < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_customer_relations_contacts_on_unique_email_per_group'

  def up
    add_concurrent_index :customer_relations_contacts, 'group_id, lower(email), id', name: INDEX_NAME, unique: true
  end

  def down
    remove_concurrent_index_by_name :customer_relations_contacts, INDEX_NAME
  end
end
