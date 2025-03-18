# frozen_string_literal: true

class AddFkOrganizationUsersOrganizations < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.10'

  def up
    add_concurrent_foreign_key :organization_users, :organizations, column: :organization_id, on_delete: :restrict,
      validate: false
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :organization_users, column: :organization_id
    end
  end
end
