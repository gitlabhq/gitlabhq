# frozen_string_literal: true

class AddExperienceLevelToUserPreferences < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :user_preferences, :experience_level, :integer, limit: 2
  end
end
