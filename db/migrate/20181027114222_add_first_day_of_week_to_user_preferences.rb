# frozen_string_literal: true

class AddFirstDayOfWeekToUserPreferences < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :user_preferences, :first_day_of_week, :integer
  end
end
