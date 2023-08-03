# frozen_string_literal: true

class AddEmailResetOfferedAtToUserDetails < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :user_details, :email_reset_offered_at, :datetime_with_timezone
  end
end
