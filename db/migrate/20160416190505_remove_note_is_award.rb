# rubocop:disable all
class RemoveNoteIsAward < ActiveRecord::Migration
  def change
    remove_column :notes, :is_award, :boolean
  end
end
