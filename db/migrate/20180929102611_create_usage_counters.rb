# frozen_string_literal: true

class CreateUsageCounters < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :usage_counters do |t|
      t.integer :web_ide_commits

      t.timestamps_with_timezone null: false
    end
  end
end
