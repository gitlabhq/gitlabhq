# frozen_string_literal: true

class ValidateUserTypeConstraint < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    validate_not_null_constraint(:users, :user_type)
  end

  def down
    # no-op
  end
end
