# frozen_string_literal: true

class AddUsersFkToImportUserCredentials < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :import_user_credentials, :users, column: :user_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :import_user_credentials, column: :user_id
    end
  end
end
