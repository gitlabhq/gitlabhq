class AddHideProjectLimitToUsers < ActiveRecord::Migration
  def change
    add_column :users, :hide_project_limit, :boolean, default: false
  end
end
