class AddScheduleToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :always_build, :boolean, default: false, null: false
    add_column :projects, :polling_interval, :string, null: true
  end
end
