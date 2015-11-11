class AddNotesLineCodeIndex < ActiveRecord::Migration
  def change
    add_index :notes, :line_code
  end
end
