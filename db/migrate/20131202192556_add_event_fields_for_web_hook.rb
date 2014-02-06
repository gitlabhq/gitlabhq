class AddEventFieldsForWebHook < ActiveRecord::Migration
  def change
    add_column :web_hooks, :push_events, :boolean, default: true, null: false
    add_column :web_hooks, :issues_events, :boolean, default: false, null: false
    add_column :web_hooks, :merge_requests_events, :boolean, default: false, null: false
  end
end
