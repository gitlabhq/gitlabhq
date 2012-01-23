class FixNoteableId < ActiveRecord::Migration
  def up
    change_column :notes, :noteable_id, :string, :limit => 255
  end

  def down
  end
end
