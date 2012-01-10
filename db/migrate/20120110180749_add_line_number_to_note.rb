class AddLineNumberToNote < ActiveRecord::Migration
  def change
    add_column :notes, :line_code, :string, :null => true
  end
end
