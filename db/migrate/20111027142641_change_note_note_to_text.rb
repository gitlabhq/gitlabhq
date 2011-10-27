class ChangeNoteNoteToText < ActiveRecord::Migration
  def up
    change_column :notes, :note, :text
  end

  def down
  end
end
