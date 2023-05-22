# frozen_string_literal: true

class AddForeignKeyForUserIdToImportFailures < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :import_failures, :users, column: :user_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :import_failures, column: :user_id
    end
  end
end
