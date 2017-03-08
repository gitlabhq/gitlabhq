class RemoveColumnsForServices < ActiveRecord::Migration
  def change
    remove_column :services, :username, :string
    remove_column :services, :password, :string
    remove_column :services, :jira_issue_transition_id, :string
    remove_column :services, :api_version, :string
  end
end
