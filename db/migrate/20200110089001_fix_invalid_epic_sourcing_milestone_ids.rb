# frozen_string_literal: true

class FixInvalidEpicSourcingMilestoneIds < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    nullify_invalid_data(:start_date_sourcing_milestone_id)
    nullify_invalid_data(:due_date_sourcing_milestone_id)
  end

  def down
    # no-op
  end

  private

  def nullify_invalid_data(column_name)
    execute(<<-SQL.squish)
      UPDATE epics
      SET #{column_name} = null
      WHERE #{column_name} NOT IN (SELECT id FROM milestones);
    SQL
  end
end
