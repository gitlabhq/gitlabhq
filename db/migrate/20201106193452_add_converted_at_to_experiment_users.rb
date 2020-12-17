# frozen_string_literal: true

class AddConvertedAtToExperimentUsers < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :experiment_users, :converted_at, :datetime_with_timezone
  end
end
