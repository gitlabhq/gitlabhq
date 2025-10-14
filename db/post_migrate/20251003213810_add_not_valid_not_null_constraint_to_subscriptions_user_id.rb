# frozen_string_literal: true

class AddNotValidNotNullConstraintToSubscriptionsUserId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  def up
    add_not_null_constraint :subscriptions, :user_id, validate: false
  end

  def down
    remove_not_null_constraint :subscriptions, :user_id
  end
end
