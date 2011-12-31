class AddProjectIdToKey < ActiveRecord::Migration
  def change
    add_column :keys, :project_id, :integer, :null => true
    change_column :keys, :user_id, :integer, :null => true
  end
end
