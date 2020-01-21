# frozen_string_literal: true

class AddEpicDateSourcingMilestoneIndexes < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :epics, due_date_column
    add_concurrent_index :epics, start_date_column
  end

  def down
    remove_concurrent_index :epics, start_date_column
    remove_concurrent_index :epics, due_date_column
  end

  private

  def due_date_column
    :due_date_sourcing_milestone_id
  end

  def start_date_column
    :start_date_sourcing_milestone_id
  end
end
