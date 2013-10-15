class AddConfirmableToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string
    add_index :users, :confirmation_token, unique: true
    User.update_all(confirmed_at: Time.now)
  end

  def self.down
    remove_column :users, :confirmation_token, :confirmed_at, :confirmation_sent_at
    remove_column :users, :unconfirmed_email
  end
end
