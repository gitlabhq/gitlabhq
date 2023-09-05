# frozen_string_literal: true

class IndexOrgIdAndIdOnOrganizationUser < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_organization_users_on_organization_id_and_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :organization_users, %i[organization_id id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :organization_users, INDEX_NAME
  end
end
