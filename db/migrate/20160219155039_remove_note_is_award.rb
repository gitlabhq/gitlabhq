class RemoveNoteIsAward < ActiveRecord::Migration
  def change
    remove_column :notes, :is_award
  end
end
