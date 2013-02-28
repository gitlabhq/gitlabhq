class AddIssuesTrackerIdToProject < ActiveRecord::Migration
  def change
    add_column :projects, :issues_tracker_id, :string
  end
end
