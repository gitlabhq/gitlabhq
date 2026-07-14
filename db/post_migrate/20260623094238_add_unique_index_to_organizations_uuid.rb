# frozen_string_literal: true

class AddUniqueIndexToOrganizationsUuid < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  INDEX_NAME = 'index_organizations_on_uuid'

  def up
    add_concurrent_index :organizations, :uuid, unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :organizations, INDEX_NAME
  end
end
