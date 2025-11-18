# frozen_string_literal: true

class AddOrganizationIdFkToLdapAdminRoleLinks < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def up
    add_concurrent_foreign_key :ldap_admin_role_links, :organizations, column: :organization_id, validate: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :ldap_admin_role_links, column: :organization_id
    end
  end
end
