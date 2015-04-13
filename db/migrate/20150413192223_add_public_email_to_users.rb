class AddPublicEmailToUsers < ActiveRecord::Migration
  def change
    remove_column :users, :email_display_in_profile
    add_column :users, :public_email, :string, default: "", null: false
  end
end
