class AddFilterToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :build_branches, :boolean, default: true, null: false
    add_column :jobs, :build_tags, :boolean, default: false, null: false
  end
end
