# frozen_string_literal: true

class AddColumnStateToPiplUsers < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  def change
    add_column :pipl_users, :state, :smallint, default: 0, null: false
  end
end
