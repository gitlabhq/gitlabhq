class AddMergeRequestsForDevelopersEnabledToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :merge_request_for_developers_enabled, :boolean, :default => false
  end
end
