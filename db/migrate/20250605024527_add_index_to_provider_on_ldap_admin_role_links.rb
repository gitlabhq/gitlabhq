# frozen_string_literal: true

class AddIndexToProviderOnLdapAdminRoleLinks < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  disable_ddl_transaction!

  INDEX_NAME = 'index_ldap_admin_role_links_on_provider_and_sync_status'

  def up
    add_concurrent_index :ldap_admin_role_links, [:provider, :sync_status], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ldap_admin_role_links, name: INDEX_NAME
  end
end
