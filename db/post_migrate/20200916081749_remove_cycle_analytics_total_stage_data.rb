# frozen_string_literal: true

class RemoveCycleAnalyticsTotalStageData < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    execute("DELETE FROM analytics_cycle_analytics_group_stages WHERE name='production'")
    execute("DELETE FROM analytics_cycle_analytics_project_stages WHERE name='production'")
  end

  def down
    # Migration is irreversible
  end
end
