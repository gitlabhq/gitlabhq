class AddPositionsToDiffNotes < ActiveRecord::Migration[4.2]
  def change
    add_column :notes, :position, :text
    add_column :notes, :original_position, :text
  end
end
