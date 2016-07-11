class AddPositionsToDiffNotes < ActiveRecord::Migration
  def change
    add_column :notes, :position, :text
    add_column :notes, :original_position, :text
  end
end
