class AddProjectsVisibilityLevelIndex < ActiveRecord::Migration
  def change
    add_index :projects, :visibility_level
  end
end
