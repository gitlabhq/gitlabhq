class ExpandDiffColumnSize < ActiveRecord::Migration
  def up
    change_column :notes, :st_diff, :text, :limit => 4294967295
  end

  def down
  end
end
