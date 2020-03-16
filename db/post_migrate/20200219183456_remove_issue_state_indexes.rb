# frozen_string_literal: true

class RemoveIssueStateIndexes < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  # issues state column is ignored since 12.6 and will be removed on a following migration
  def up
    remove_concurrent_index_by_name :issues, 'index_issues_on_state'
    remove_concurrent_index_by_name :issues, 'index_issues_on_project_id_and_created_at_and_id_and_state'
    remove_concurrent_index_by_name :issues, 'idx_issues_on_project_id_and_due_date_and_id_and_state_partial'
    remove_concurrent_index_by_name :issues, 'index_issues_on_project_id_and_rel_position_and_state_and_id'
    remove_concurrent_index_by_name :issues, 'index_issues_on_project_id_and_updated_at_and_id_and_state'
  end

  def down
    add_concurrent_index :issues, :state, name: 'index_issues_on_state'

    add_concurrent_index :issues,
                         [:project_id, :created_at, :id, :state],
                         name: 'index_issues_on_project_id_and_created_at_and_id_and_state'

    add_concurrent_index :issues,
                         [:project_id, :due_date, :id, :state],
                         where: 'due_date IS NOT NULL',
                         name: 'idx_issues_on_project_id_and_due_date_and_id_and_state_partial'

    add_concurrent_index :issues,
                         [:project_id, :relative_position, :state, :id],
                         order: { id: :desc },
                         name: 'index_issues_on_project_id_and_rel_position_and_state_and_id'

    add_concurrent_index :issues,
                         [:project_id, :updated_at, :id, :state],
                         name: 'index_issues_on_project_id_and_updated_at_and_id_and_state'
  end
end
