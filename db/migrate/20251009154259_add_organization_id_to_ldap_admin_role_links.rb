# frozen_string_literal: true

class AddOrganizationIdToLdapAdminRoleLinks < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def change
    add_column :ldap_admin_role_links, :organization_id, :bigint
  end
end
