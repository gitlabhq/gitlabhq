# rubocop:disable all
class AddIsAwardToNotes < ActiveRecord::Migration[4.2]
  def change
    add_column :notes, :is_award, :boolean, default: false, null: false
    add_index :notes, :is_award
  end
end
