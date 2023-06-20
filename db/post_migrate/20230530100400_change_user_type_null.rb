# frozen_string_literal: true

class ChangeUserTypeNull < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_not_null_constraint :users, :user_type, validate: false
  end

  def down
    remove_not_null_constraint :users, :user_type
  end
end
