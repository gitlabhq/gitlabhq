class RemovePathFieldFromProject < ActiveRecord::Migration
  def up
    remove_column :projects, :path
  end

  def down
  end
end
