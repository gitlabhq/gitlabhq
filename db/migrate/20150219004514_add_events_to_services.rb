class AddEventsToServices < ActiveRecord::Migration
  def change
    add_column :services, :push_events, :boolean, :default => true
    add_column :services, :issues_events, :boolean, :default => true
    add_column :services, :merge_requests_events, :boolean, :default => true
    add_column :services, :tag_push_events, :boolean, :default => true
  end
end
