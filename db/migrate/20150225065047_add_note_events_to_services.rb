# rubocop:disable all
class AddNoteEventsToServices < ActiveRecord::Migration[4.2]
  def change
    add_column :services, :note_events, :boolean, default: true, null: false
  end
end
