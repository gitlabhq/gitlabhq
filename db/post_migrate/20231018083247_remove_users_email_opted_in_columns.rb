# frozen_string_literal: true

class RemoveUsersEmailOptedInColumns < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    remove_column :users, :email_opted_in
    remove_column :users, :email_opted_in_ip
    remove_column :users, :email_opted_in_source_id
    remove_column :users, :email_opted_in_at
  end

  def down
    add_column :users, :email_opted_in, :boolean
    add_column :users, :email_opted_in_ip, :string
    add_column :users, :email_opted_in_source_id, :integer
    add_column :users, :email_opted_in_at, :datetime_with_timezone
  end
end
