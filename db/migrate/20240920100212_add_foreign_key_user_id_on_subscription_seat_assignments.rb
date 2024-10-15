# frozen_string_literal: true

class AddForeignKeyUserIdOnSubscriptionSeatAssignments < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :subscription_seat_assignments, :users, column: :user_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :subscription_seat_assignments, column: :user_id
    end
  end
end
