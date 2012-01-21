class FixNoteableId < ActiveRecord::Migration
  def up
    change_column :notes, :noteable_id, :string, :limit => 255
  end

  def down
    change_column :notes, :noteable_id, :integer, :limit => 11
  end
end
