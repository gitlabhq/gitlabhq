class AddBuildEventsToServices < ActiveRecord::Migration
  def change
    add_column :services, :build_events, :boolean, default: false, null: false
    add_column :web_hooks, :build_events, :boolean, default: false, null: false
  end
end
