class AddUnlockTokenToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :unlock_token, :string
  end
end
