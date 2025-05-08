# frozen_string_literal: true

class AddPlaceholderUserForeignKeyToImportPlaceholderUserDetails < Gitlab::Database::Migration[2.3]
  milestone '18.0'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :import_placeholder_user_details, :users, column: :placeholder_user_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :import_placeholder_user_details, column: :placeholder_user_id
    end
  end
end
