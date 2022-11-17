# frozen_string_literal: true

class ChangeDefaultValueOnPasswordLastChangedAtToUserDetails < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  # rubocop:disable Migration/RemoveColumn
  def change
    remove_column :user_details, :password_last_changed_at, :datetime_with_timezone
    add_column :user_details, :password_last_changed_at, :datetime_with_timezone,
               null: false, default: -> { 'NOW()' }, comment: 'JiHu-specific column'
  end
  # rubocop:enable Migration/RemoveColumn
end
