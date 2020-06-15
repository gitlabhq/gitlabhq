# frozen_string_literal: true

class RemoveNotNullConstraintFromMilestoneEventsTable < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    change_column_null :resource_milestone_events, :user_id, true
  end
end
