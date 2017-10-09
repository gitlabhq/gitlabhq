# rubocop:disable all
class AddIssuesTrackerToProject < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :issues_tracker, :string, default: :gitlab, null: false
  end
end
