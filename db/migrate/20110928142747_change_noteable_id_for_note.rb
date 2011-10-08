class ChangeNoteableIdForNote < ActiveRecord::Migration
  def up
    change_column :notes, :noteable_id, :string
  end

  def down
    change_column :notes, :noteable_id, :integer
  end
end
