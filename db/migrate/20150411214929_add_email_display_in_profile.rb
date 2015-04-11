class AddEmailDisplayInProfile < ActiveRecord::Migration
  def change
    add_column :users, :email_display_in_profile, :boolean, default: false, null: false
  end
end
