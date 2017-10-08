# rubocop:disable all
class AddNotesLineCodeIndex < ActiveRecord::Migration[4.2]
  def change
    add_index :notes, :line_code
  end
end
