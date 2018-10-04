class AddNotificationEmailToUser < ActiveRecord::Migration
  def up
    add_column :users, :notification_email, :string

    execute "UPDATE users SET notification_email = email"
  end

  def down
    remove_column :users, :notification_email
  end
end
