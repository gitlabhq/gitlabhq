# frozen_string_literal: true

class AddEpicDueDateSourcingMilestoneIdForeignKey < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :epics, :milestones, column: due_date_column, on_delete: :nullify, validate: false
  end

  def down
    remove_foreign_key_if_exists :epics, column: due_date_column
  end

  private

  def due_date_column
    :due_date_sourcing_milestone_id
  end
end
