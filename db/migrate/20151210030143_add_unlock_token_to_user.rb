class AddUnlockTokenToUser < ActiveRecord::Migration
  def change
    add_column :users, :unlock_token, :string
  end
end
