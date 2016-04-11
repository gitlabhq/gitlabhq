class AddVisibilityLevelToProjects < ActiveRecord::Migration
  include Gitlab::Database

  def self.up
    add_column :projects, :visibility_level, :integer, :default => 0, :null => false
    execute("UPDATE projects SET visibility_level = #{Gitlab::VisibilityLevel::PUBLIC} WHERE public = #{true_value}")
    remove_column :projects, :public
  end

  def self.down
    add_column :projects, :public, :boolean, :default => false, :null => false
    execute("UPDATE projects SET public = #{true_value} WHERE visibility_level = #{Gitlab::VisibilityLevel::PUBLIC}")
    remove_column :projects, :visibility_level
  end
end
