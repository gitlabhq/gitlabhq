class AddPermissionCheckToUser < ActiveRecord::Migration
  def change
    add_column :users, :last_credential_check_at, :datetime
  end
end
