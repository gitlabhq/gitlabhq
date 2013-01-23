class AddIssuesTrackerToProject < ActiveRecord::Migration
  def change
    add_column :projects, :issues_tracker, :string, default: :gitlab, null: false
  end
end
