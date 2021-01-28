# frozen_string_literal: true

class AddSubgroupEventsToWebHooks < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :web_hooks, :subgroup_events, :boolean, null: false, default: false
  end
end
