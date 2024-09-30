# frozen_string_literal: true

class AddIndexToSubscriptions < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.5'

  INDEX_NAME = 'index_subscriptions_on_user'

  def up
    add_concurrent_index :subscriptions, :user_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :subscriptions, :user_id, name: INDEX_NAME
  end
end
