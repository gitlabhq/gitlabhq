# frozen_string_literal: true

class AddCadenceToDastProfileSchedules < ActiveRecord::Migration[6.1]
  def change
    add_column :dast_profile_schedules, :cadence, :jsonb, null: false, default: {}
  end
end
