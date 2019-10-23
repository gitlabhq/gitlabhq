# frozen_string_literal: true

class AddSourcingEpicDates < ActiveRecord::Migration[5.1]
  DOWNTIME = false

  def change
    add_column :epics, :start_date_sourcing_epic_id, :integer
    add_column :epics, :due_date_sourcing_epic_id, :integer
  end
end
