# frozen_string_literal: true

class AddIssuesMilestoneAndIdIndexConcurrently < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  INDEX_NAME = 'index_issues_on_milestone_id_and_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :issues, %i[milestone_id id], name: INDEX_NAME # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
  end

  def down
    remove_concurrent_index_by_name :issues, INDEX_NAME
  end
end
