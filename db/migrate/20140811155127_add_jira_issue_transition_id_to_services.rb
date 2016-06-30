# rubocop:disable all
class AddJiraIssueTransitionIdToServices < ActiveRecord::Migration
  def up
    add_column :services, :jira_issue_transition_id, :string, default: '2'
    Service.reset_column_information
    Service.where(jira_issue_transition_id: nil).update_all jira_issue_transition_id: '2'
  end

  def down
    remove_column :services, :jira_issue_transition_id
  end
end
