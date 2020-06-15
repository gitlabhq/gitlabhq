# frozen_string_literal: true

class RemoveNotNullConstraintFromWeightEventsTable < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    change_column_null :resource_weight_events, :user_id, true
  end
end
