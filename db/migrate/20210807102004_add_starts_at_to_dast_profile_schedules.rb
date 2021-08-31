# frozen_string_literal: true

class AddStartsAtToDastProfileSchedules < ActiveRecord::Migration[6.1]
  def change
    add_column :dast_profile_schedules, :starts_at, :datetime_with_timezone, null: false, default: -> { 'NOW()' }
  end
end
