# frozen_string_literal: true

class RemoveOrganizationsOrganizationUsersOrganizationIdFk < Gitlab::Database::Migration[2.2]
  milestone '16.8'
  disable_ddl_transaction!

  FOREIGN_KEY_NAME = "fk_8471abad75"

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:organization_users, :organizations,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:organization_users, :organizations,
      name: FOREIGN_KEY_NAME, column: :organization_id,
      target_column: :id, on_delete: :cascade)
  end
end
