# rubocop:disable all
class ChangeProjectIdToNullInSnipepts < ActiveRecord::Migration[4.2]
  def up
    change_column :snippets, :project_id, :integer, :null => true
  end

  def down
    change_column :snippets, :project_id, :integer, :null => false
  end
end
