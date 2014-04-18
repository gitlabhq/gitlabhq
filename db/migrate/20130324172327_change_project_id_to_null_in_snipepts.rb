class ChangeProjectIdToNullInSnipepts < ActiveRecord::Migration
  def up
    change_column :snippets, :project_id, :integer, :null => true
  end

  def down
    change_column :snippets, :project_id, :integer, :null => false
  end
end
