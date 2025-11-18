# frozen_string_literal: true

class AddIndexOnOrganizationIdToLdapAdminRoleLinks < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  INDEX_NAME = 'index_ldap_admin_role_links_on_organization_id'

  def up
    add_concurrent_index :ldap_admin_role_links, :organization_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ldap_admin_role_links, INDEX_NAME
  end
end
