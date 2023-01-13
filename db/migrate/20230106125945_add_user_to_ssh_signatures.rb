# frozen_string_literal: true

class AddUserToSshSignatures < Gitlab::Database::Migration[2.1]
  def up
    add_column :ssh_signatures, :user_id, :bigint, if_not_exists: true, null: true
  end

  def down
    remove_column :ssh_signatures, :user_id, if_exists: true
  end
end
