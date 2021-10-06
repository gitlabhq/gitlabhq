# frozen_string_literal: true

class AddExternalEventDestinationLimitToPlanLimits < Gitlab::Database::Migration[1.0]
  def change
    add_column(:plan_limits, :external_audit_event_destinations, :integer, default: 5, null: false)
  end
end
