class AddVisibilityLevelToProjects < ActiveRecord::Migration
  def self.up
    add_column :projects, :visibility_level, :integer, :default => 0, :null => false
    Project.where(public: true).update_all(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
    remove_column :projects, :public
  end

  def self.down
    add_column :projects, :public, :boolean, :default => false, :null => false
    Project.where(visibility_level: Gitlab::VisibilityLevel::PUBLIC).update_all(public: true)
    remove_column :projects, :visibility_level
  end
end
