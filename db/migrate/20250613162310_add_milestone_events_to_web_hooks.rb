# frozen_string_literal: true

class AddMilestoneEventsToWebHooks < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def change
    add_column :web_hooks, :milestone_events, :boolean, null: false, default: false
  end
end
