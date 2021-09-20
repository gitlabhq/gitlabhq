# frozen_string_literal: true

class CreateForeignKeyOnContactsGroupId < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_customer_relations_contacts_on_group_id'

  def up
    add_concurrent_index :customer_relations_contacts, :group_id, name: INDEX_NAME
    add_concurrent_foreign_key :customer_relations_contacts, :namespaces, column: :group_id
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :customer_relations_contacts, column: :group_id
    end

    remove_concurrent_index_by_name :customer_relations_contacts, INDEX_NAME
  end
end
