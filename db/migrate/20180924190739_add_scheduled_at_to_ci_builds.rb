# frozen_string_literal: true

class AddScheduledAtToCiBuilds < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    add_column :ci_builds, :scheduled_at, :datetime_with_timezone
  end
end
