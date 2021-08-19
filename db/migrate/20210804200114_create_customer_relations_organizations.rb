# frozen_string_literal: true

class CreateCustomerRelationsOrganizations < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    create_table_with_constraints :customer_relations_organizations do |t|
      t.references :group, index: false, null: false, foreign_key: { to_table: :namespaces, on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.integer :state, limit: 1, default: 1, null: false
      t.decimal :default_rate, precision: 18, scale: 2
      t.text :name, null: false
      t.text :description

      t.text_limit :name, 255
      t.text_limit :description, 1024

      t.index 'group_id, LOWER(name)', unique: true, name: :index_customer_relations_organizations_on_unique_name_per_group
    end
  end

  def down
    with_lock_retries do
      drop_table :customer_relations_organizations
    end
  end
end
