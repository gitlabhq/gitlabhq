# frozen_string_literal: true

class AddTabWidthToUserPreferences < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column(:user_preferences, :tab_width, :integer, limit: 2)
  end
end
