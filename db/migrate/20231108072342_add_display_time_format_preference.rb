# frozen_string_literal: true

class AddDisplayTimeFormatPreference < Gitlab::Database::Migration[2.2]
  milestone '16.6'
  enable_lock_retries!

  def change
    add_column :user_preferences, :time_display_format, :integer, limit: 2, default: 0, null: false
  end
end
