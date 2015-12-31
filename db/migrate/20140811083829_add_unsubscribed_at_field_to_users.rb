class AddUnsubscribedAtFieldToUsers < ActiveRecord::Migration
  def change
    add_column :users, :admin_email_unsubscribed_at, :datetime
  end
end
