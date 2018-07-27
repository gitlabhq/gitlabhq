class AddNullToNameForCiProjects < ActiveRecord::Migration
  def up
    change_column_null :ci_projects, :name, true
  end

  def down
    change_column_null :ci_projects, :name, false
  end
end
