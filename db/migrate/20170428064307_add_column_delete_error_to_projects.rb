class AddColumnDeleteErrorToProjects < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    add_column :projects, :delete_error, :text
  end
end
