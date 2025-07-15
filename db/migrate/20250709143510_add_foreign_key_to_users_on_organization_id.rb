# frozen_string_literal: true

class AddForeignKeyToUsersOnOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :users, :organizations,
      column: :organization_id,
      target_column: :id,
      validate: false,
      on_delete: false
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :users, :organizations, column: :organization_id
    end
  end
end
