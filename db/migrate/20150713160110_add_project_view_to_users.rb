class AddProjectViewToUsers < ActiveRecord::Migration
  def change
    add_column :users, :project_view, :integer, default: 0
  end
end
