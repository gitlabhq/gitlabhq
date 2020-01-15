# frozen_string_literal: true

class ValidateForeignKeyEpicDueDateSourcingMilestone < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    validate_foreign_key(:epics, :due_date_sourcing_milestone_id)
  end

  def down
    # no-op
  end
end
