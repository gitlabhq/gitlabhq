class AddIsAwardToNotes < ActiveRecord::Migration
  def change
    add_column :notes, :is_award, :boolean, default: false
  end
end
