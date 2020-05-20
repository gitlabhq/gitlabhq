# frozen_string_literal: true

class SprintMakeStateEnumNotNullAndDefault < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    change_column_default :sprints, :state_enum, from: 0, to: 1
    change_column_null :sprints, :state_enum, false, 1
  end

  def down
    change_column_null :sprints, :state_enum, true
    change_column_default :sprints, :state_enum, from: 1, to: nil
  end
end
