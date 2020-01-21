# frozen_string_literal: true

class AddEpicStartDateSourcingMilestoneIdForeignKey < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :epics, :milestones, column: start_date_column, on_delete: :nullify, validate: false
  end

  def down
    remove_foreign_key_if_exists :epics, column: start_date_column
  end

  private

  def start_date_column
    :start_date_sourcing_milestone_id
  end
end
