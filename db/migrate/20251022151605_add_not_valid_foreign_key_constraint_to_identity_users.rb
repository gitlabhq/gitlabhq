# frozen_string_literal: true

class AddNotValidForeignKeyConstraintToIdentityUsers < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def up
    add_concurrent_foreign_key(
      :identities,
      :users,
      column: :user_id,
      on_delete: :cascade,
      validate: false
    )
  end

  def down
    remove_foreign_key_if_exists :identities, column: :user_id
  end
end
