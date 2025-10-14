# frozen_string_literal: true

class AddNotNullToAdminRolesOrganizationId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  def up
    add_not_null_constraint(:admin_roles, :organization_id)
  end

  def down
    remove_not_null_constraint(:admin_roles, :organization_id)
  end
end
