# frozen_string_literal: true

class AddNotValidFkOnSubscriptionsUserId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  def up
    add_concurrent_foreign_key :subscriptions, :users, column: :user_id, validate: false
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :subscriptions, column: :user_id
    end
  end
end
