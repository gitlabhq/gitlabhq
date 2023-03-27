# frozen_string_literal: true

class ChangeUserTypeDefault < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    change_column_default :users, :user_type, 0
  end

  def down
    change_column_default :users, :user_type, nil
  end
end
