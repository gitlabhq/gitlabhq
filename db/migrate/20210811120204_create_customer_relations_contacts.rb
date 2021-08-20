# frozen_string_literal: true

class CreateCustomerRelationsContacts < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    create_table_with_constraints :customer_relations_contacts do |t|
      t.bigint :group_id, null: false
      t.references :organization, index: true, null: true, foreign_key: { to_table: :customer_relations_organizations, on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.integer :state, limit: 1, default: 1, null: false
      t.text :phone
      t.text :first_name, null: false
      t.text :last_name, null: false
      t.text :email
      t.text :description

      t.text_limit :phone, 32
      t.text_limit :first_name, 255
      t.text_limit :last_name, 255
      t.text_limit :email, 255
      t.text_limit :description, 1024
    end
  end

  def down
    with_lock_retries do
      drop_table :customer_relations_contacts
    end
  end
end
