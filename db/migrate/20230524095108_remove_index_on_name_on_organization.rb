# frozen_string_literal: true

class RemoveIndexOnNameOnOrganization < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'unique_organizations_on_name_lower'

  def up
    remove_concurrent_index_by_name :organizations, INDEX_NAME
  end

  def down
    add_concurrent_index :organizations, 'lower(name)', name: INDEX_NAME
  end
end
