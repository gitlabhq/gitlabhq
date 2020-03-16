# frozen_string_literal: true

class AddProjectSubscriptionsToPlanLimits < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column(:plan_limits, :ci_project_subscriptions, :integer, default: 0, null: false)
  end
end
