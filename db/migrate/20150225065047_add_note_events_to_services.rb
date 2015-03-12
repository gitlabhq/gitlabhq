class AddNoteEventsToServices < ActiveRecord::Migration
  def change
    add_column :services, :note_events, :boolean, default: true, null: false
  end
end
