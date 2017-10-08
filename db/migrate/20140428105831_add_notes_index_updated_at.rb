# rubocop:disable all
class AddNotesIndexUpdatedAt < ActiveRecord::Migration[4.2]
  def change
    add_index :notes, :updated_at
  end
end
