# frozen_string_literal: true

class AddForeignKeyToOrganizationUsersOnUserId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.5'

  def up
    add_concurrent_foreign_key(:organization_users, :users, column: :user_id, on_delete: :cascade, validate: false)
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(:organization_users, column: :user_id)
    end
  end
end
