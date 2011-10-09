class AddProjectsLimitToUser < ActiveRecord::Migration
  def change
    add_column :users, :projects_limit, :integer, :default => 10
  end
end
