# frozen_string_literal: true

class AddRunnerRegistrationToPlanLimits < ActiveRecord::Migration[6.0]
  def change
    add_column(:plan_limits, :ci_registered_group_runners, :integer, default: 1000, null: false)
    add_column(:plan_limits, :ci_registered_project_runners, :integer, default: 1000, null: false)
  end
end
