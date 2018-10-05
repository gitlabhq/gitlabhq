# frozen_string_literal: true

class AddScheduledAtToCiBuilds < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :ci_builds, :scheduled_at, :datetime_with_timezone
  end
end
