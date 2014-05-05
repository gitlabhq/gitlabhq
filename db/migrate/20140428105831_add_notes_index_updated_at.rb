class AddNotesIndexUpdatedAt < ActiveRecord::Migration
  def change
    add_index :notes, :updated_at
  end
end
