# frozen_string_literal: true

class AddBrowserPerformanceToPlanLimits < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :plan_limits, "ci_max_artifact_size_browser_performance", :integer, default: 0, null: false
  end
end
