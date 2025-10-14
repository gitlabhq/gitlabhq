# frozen_string_literal: true

class AddOrganizationIdToAdminRoles < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def change
    add_column :admin_roles, :organization_id, :bigint
  end
end
