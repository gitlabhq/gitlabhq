# frozen_string_literal: true

class ValidateSubscriptionsUserIdNotNullConstraint < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def up
    validate_not_null_constraint :subscriptions, :user_id
  end

  def down
    # no-op
  end
end
