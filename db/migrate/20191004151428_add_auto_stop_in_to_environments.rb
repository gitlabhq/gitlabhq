# frozen_string_literal: true

class AddAutoStopInToEnvironments < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :environments, :auto_stop_at, :datetime_with_timezone
  end
end
