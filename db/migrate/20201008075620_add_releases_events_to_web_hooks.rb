# frozen_string_literal: true

class AddReleasesEventsToWebHooks < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :web_hooks, :releases_events, :boolean, null: false, default: false
  end
end
