# rubocop:disable all
class AddStDiffToNote < ActiveRecord::Migration[4.2]
  def change
    add_column :notes, :st_diff, :text, :null => true
  end
end
