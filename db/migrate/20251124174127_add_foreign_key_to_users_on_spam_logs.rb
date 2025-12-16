# frozen_string_literal: true

class AddForeignKeyToUsersOnSpamLogs < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    add_concurrent_foreign_key :spam_logs, :users, column: :user_id, on_delete: :cascade, validate: false
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :spam_logs, column: :user_id
    end
  end
end
