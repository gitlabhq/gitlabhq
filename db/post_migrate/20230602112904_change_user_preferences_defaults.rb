# frozen_string_literal: true

class ChangeUserPreferencesDefaults < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    change_column_default(:user_preferences, :tab_width, from: nil, to: 8)
    change_column_default(:user_preferences, :time_display_relative, from: nil, to: true)
    change_column_default(:user_preferences, :render_whitespace_in_code, from: nil, to: false)
  end
end
