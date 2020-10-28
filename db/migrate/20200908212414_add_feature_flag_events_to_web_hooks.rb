# frozen_string_literal: true

class AddFeatureFlagEventsToWebHooks < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :web_hooks, :feature_flag_events, :boolean, null: false, default: false
  end
end
