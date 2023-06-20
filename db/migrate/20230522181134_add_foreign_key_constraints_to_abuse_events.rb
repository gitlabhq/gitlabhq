# frozen_string_literal: true

class AddForeignKeyConstraintsToAbuseEvents < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :abuse_events, :users, column: :user_id, on_delete: :nullify, null: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :abuse_events, column: :user_id
    end
  end
end
