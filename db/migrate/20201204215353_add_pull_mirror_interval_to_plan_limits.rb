# frozen_string_literal: true

class AddPullMirrorIntervalToPlanLimits < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :plan_limits, :pull_mirror_interval_seconds, :integer, default: 300, null: false
  end
end
