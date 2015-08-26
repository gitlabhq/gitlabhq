class IncreateTraceColunmLimit < ActiveRecord::Migration
  def up
    change_column :builds, :trace, :text, :limit => 1073741823
  end

  def down
  end
end
