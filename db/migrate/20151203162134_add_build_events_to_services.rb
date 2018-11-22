# rubocop:disable all
class AddBuildEventsToServices < ActiveRecord::Migration[4.2]
  def change
    add_column :services, :build_events, :boolean, default: false, null: false
    add_column :web_hooks, :build_events, :boolean, default: false, null: false
  end
end
