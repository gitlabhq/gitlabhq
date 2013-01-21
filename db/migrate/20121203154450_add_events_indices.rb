class AddEventsIndices < ActiveRecord::Migration
  def change
    add_index :events, :project_id
    add_index :events, :author_id
    add_index :events, :action
    add_index :events, :target_type
  end
end
