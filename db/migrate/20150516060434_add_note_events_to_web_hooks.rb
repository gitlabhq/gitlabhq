class AddNoteEventsToWebHooks < ActiveRecord::Migration
  def up
    add_column :web_hooks, :note_events, :boolean, default: false, null: false
  end

  def down
    remove_column :web_hooks, :note_events, :boolean
  end
end
