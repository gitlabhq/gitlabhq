# frozen_string_literal: true

class AddProjectEventsToWebHooks < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    add_column :web_hooks, :project_events, :boolean, null: false, default: false
  end
end
