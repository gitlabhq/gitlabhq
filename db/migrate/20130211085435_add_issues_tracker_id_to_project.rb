# rubocop:disable all
class AddIssuesTrackerIdToProject < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :issues_tracker_id, :string
  end
end
