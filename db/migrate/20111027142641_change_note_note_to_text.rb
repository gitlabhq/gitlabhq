class ChangeNoteNoteToText < ActiveRecord::Migration
  def up
    change_column :notes, :note, :text, :limit => false
  end

  def down
  end
end
