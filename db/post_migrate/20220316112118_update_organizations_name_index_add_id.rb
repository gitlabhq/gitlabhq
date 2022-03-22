# frozen_string_literal: true

class UpdateOrganizationsNameIndexAddId < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  OLD_INDEX = 'index_customer_relations_organizations_on_unique_name_per_group'
  NEW_INDEX = 'index_organizations_on_unique_name_per_group'

  def up
    add_concurrent_index :customer_relations_organizations, 'group_id, lower(name), id', name: NEW_INDEX, unique: true

    remove_concurrent_index_by_name :customer_relations_organizations, OLD_INDEX
  end

  def down
    add_concurrent_index :customer_relations_organizations, 'group_id, lower(name)', name: OLD_INDEX, unique: true

    remove_concurrent_index_by_name :customer_relations_organizations, NEW_INDEX
  end
end
