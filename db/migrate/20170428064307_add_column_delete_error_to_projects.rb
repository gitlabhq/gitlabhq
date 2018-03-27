class AddColumnDeleteErrorToProjects < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :projects, :delete_error, :text
  end
end
