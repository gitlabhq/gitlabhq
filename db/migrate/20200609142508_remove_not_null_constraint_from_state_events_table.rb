# frozen_string_literal: true

class RemoveNotNullConstraintFromStateEventsTable < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    change_column_null :resource_state_events, :user_id, true
  end
end
