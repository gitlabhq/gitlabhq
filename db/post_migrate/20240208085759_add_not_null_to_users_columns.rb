# frozen_string_literal: true

class AddNotNullToUsersColumns < Gitlab::Database::Migration[2.2]
  milestone '16.9'
  disable_ddl_transaction!

  COLUMNS = %i[hide_no_ssh_key hide_no_password project_view notified_of_own_activity]

  def up
    COLUMNS.each do |column|
      add_not_null_constraint :users, column
    end
  end

  def down
    COLUMNS.each do |column|
      remove_not_null_constraint :users, column
    end
  end
end
