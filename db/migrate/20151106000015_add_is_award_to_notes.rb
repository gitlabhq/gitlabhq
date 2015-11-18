class AddIsAwardToNotes < ActiveRecord::Migration
  def change
    add_column :notes, :is_award, :boolean, default: false, null: false
    add_index :notes, :is_award
  end
end
