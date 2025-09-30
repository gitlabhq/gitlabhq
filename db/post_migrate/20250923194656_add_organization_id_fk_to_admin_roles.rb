# frozen_string_literal: true

class AddOrganizationIdFkToAdminRoles < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  def up
    add_concurrent_foreign_key :admin_roles, :organizations, column: :organization_id, validate: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :admin_roles, column: :organization_id
    end
  end
end
