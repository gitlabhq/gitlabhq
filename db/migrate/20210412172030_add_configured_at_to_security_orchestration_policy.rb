# frozen_string_literal: true

class AddConfiguredAtToSecurityOrchestrationPolicy < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :security_orchestration_policy_configurations, :configured_at, :datetime_with_timezone, null: true
  end
end
