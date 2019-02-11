# frozen_string_literal: true

class AddFirstDayOfWeekToUserPreferences < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  def change
    add_column :user_preferences, :first_day_of_week, :integer
  end
end
