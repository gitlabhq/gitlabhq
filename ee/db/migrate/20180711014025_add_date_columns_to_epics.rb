# frozen_string_literal: true

class AddDateColumnsToEpics < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    change_table :epics do |t|
      t.boolean :start_date_is_fixed
      t.date :start_date_fixed
      t.references :start_date_sourcing_milestone
      t.boolean :due_date_is_fixed
      t.date :due_date_fixed
      t.references :due_date_sourcing_milestone
    end
  end
end
