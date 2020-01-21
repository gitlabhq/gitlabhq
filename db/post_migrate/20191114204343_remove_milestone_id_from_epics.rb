# frozen_string_literal: true

class RemoveMilestoneIdFromEpics < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    remove_column :epics, :milestone_id
  end

  def down
    add_column :epics, :milestone_id, :integer
  end
end
