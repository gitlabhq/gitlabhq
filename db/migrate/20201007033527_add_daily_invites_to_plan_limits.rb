# frozen_string_literal: true

class AddDailyInvitesToPlanLimits < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column(:plan_limits, :daily_invites, :integer, default: 0, null: false)
  end
end
