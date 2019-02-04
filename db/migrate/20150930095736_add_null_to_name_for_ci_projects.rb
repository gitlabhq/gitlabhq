class AddNullToNameForCiProjects < ActiveRecord::Migration[4.2]
  def up
    change_column_null :ci_projects, :name, true
  end

  def down
    change_column_null :ci_projects, :name, false
  end
end
