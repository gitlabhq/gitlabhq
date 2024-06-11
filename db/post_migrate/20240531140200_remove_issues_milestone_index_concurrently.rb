# frozen_string_literal: true

class RemoveIssuesMilestoneIndexConcurrently < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :issues, 'index_issues_on_milestone_id'
  end

  def down
    add_concurrent_index :issues, %i[milestone_id]
  end
end
