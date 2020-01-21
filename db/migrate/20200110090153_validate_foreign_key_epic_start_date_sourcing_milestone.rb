# frozen_string_literal: true

class ValidateForeignKeyEpicStartDateSourcingMilestone < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    validate_foreign_key(:epics, :start_date_sourcing_milestone_id)
  end

  def down
    # no-op
  end
end
