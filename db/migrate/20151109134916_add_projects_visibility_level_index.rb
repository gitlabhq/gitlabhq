# rubocop:disable all
class AddProjectsVisibilityLevelIndex < ActiveRecord::Migration[4.2]
  def change
    add_index :projects, :visibility_level
  end
end
