# frozen_string_literal: true

class RemoveForeignKeysFromU2fRegistrationsTable < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key :u2f_registrations, :users
    end
  end

  def down
    add_concurrent_foreign_key :u2f_registrations, :users, column: :user_id
  end
end
