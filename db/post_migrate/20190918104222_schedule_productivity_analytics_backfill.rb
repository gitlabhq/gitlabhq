# frozen_string_literal: true

class ScheduleProductivityAnalyticsBackfill < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    # no-op since the migration was removed
  end

  def down
    # no-op
  end
end
