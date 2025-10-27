# frozen_string_literal: true

class AddNotNullToLdapAdminRoleLinksOrganizationId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def up
    add_not_null_constraint(:ldap_admin_role_links, :organization_id)
  end

  def down
    remove_not_null_constraint(:ldap_admin_role_links, :organization_id)
  end
end
