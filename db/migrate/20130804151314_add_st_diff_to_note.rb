class AddStDiffToNote < ActiveRecord::Migration
  def change
    add_column :notes, :st_diff, :text, :null => true
  end
end
