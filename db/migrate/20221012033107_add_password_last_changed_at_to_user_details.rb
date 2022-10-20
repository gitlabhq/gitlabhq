# frozen_string_literal: true

class AddPasswordLastChangedAtToUserDetails < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :user_details, :password_last_changed_at, :datetime_with_timezone, comment: 'JiHu-specific column'
  end
end
