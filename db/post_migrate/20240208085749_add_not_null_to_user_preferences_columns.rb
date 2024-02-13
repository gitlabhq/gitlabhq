# frozen_string_literal: true

class AddNotNullToUserPreferencesColumns < Gitlab::Database::Migration[2.2]
  milestone '16.9'
  disable_ddl_transaction!

  COLUMNS = %i[tab_width time_display_relative render_whitespace_in_code]

  def up
    COLUMNS.each do |column|
      add_not_null_constraint :user_preferences, column
    end
  end

  def down
    COLUMNS.each do |column|
      remove_not_null_constraint :user_preferences, column
    end
  end
end
