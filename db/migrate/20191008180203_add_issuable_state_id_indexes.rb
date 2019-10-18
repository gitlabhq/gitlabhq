# frozen_string_literal: true

class AddIssuableStateIdIndexes < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # Creates the same indexes that are currently using state:string column
    # for issues and merge_requests tables
    create_indexes_for_issues
    create_indexes_for_merge_requests
  end

  def down
    # Removes indexes for issues
    remove_concurrent_index_by_name :issues, 'idx_issues_on_state_id'
    remove_concurrent_index_by_name :issues, 'idx_issues_on_project_id_and_created_at_and_id_and_state_id'
    remove_concurrent_index_by_name :issues, 'idx_issues_on_project_id_and_due_date_and_id_and_state_id'
    remove_concurrent_index_by_name :issues, 'idx_issues_on_project_id_and_rel_position_and_state_id_and_id'
    remove_concurrent_index_by_name :issues, 'idx_issues_on_project_id_and_updated_at_and_id_and_state_id'

    # Removes indexes from merge_requests
    remove_concurrent_index_by_name :merge_requests, 'idx_merge_requests_on_id_and_merge_jid'
    remove_concurrent_index_by_name :merge_requests, 'idx_merge_requests_on_source_project_and_branch_state_opened'
    remove_concurrent_index_by_name :merge_requests, 'idx_merge_requests_on_state_id_and_merge_status'
    remove_concurrent_index_by_name :merge_requests, 'idx_merge_requests_on_target_project_id_and_iid_opened'
  end

  def create_indexes_for_issues
    add_concurrent_index :issues, :state_id, name: 'idx_issues_on_state_id'

    add_concurrent_index :issues,
                         [:project_id, :created_at, :id, :state_id],
                         name: 'idx_issues_on_project_id_and_created_at_and_id_and_state_id'

    add_concurrent_index :issues,
                         [:project_id, :due_date, :id, :state_id],
                         where: 'due_date IS NOT NULL',
                         name: 'idx_issues_on_project_id_and_due_date_and_id_and_state_id'

    add_concurrent_index :issues,
                         [:project_id, :relative_position, :state_id, :id],
                         order: { id: :desc },
                         name: 'idx_issues_on_project_id_and_rel_position_and_state_id_and_id'

    add_concurrent_index :issues,
                         [:project_id, :updated_at, :id, :state_id],
                         name: 'idx_issues_on_project_id_and_updated_at_and_id_and_state_id'
  end

  def create_indexes_for_merge_requests
    add_concurrent_index :merge_requests,
                         [:id, :merge_jid],
                         where: 'merge_jid IS NOT NULL and state_id = 4',
                         name: 'idx_merge_requests_on_id_and_merge_jid'

    add_concurrent_index :merge_requests,
                         [:source_project_id, :source_branch],
                         where: 'state_id = 1',
                         name: 'idx_merge_requests_on_source_project_and_branch_state_opened'

    add_concurrent_index :merge_requests,
                         [:state_id, :merge_status],
                         where: "state_id = 1 AND merge_status = 'can_be_merged'",
                         name: 'idx_merge_requests_on_state_id_and_merge_status'

    add_concurrent_index :merge_requests,
                         [:target_project_id, :iid],
                         where: 'state_id = 1',
                         name: 'idx_merge_requests_on_target_project_id_and_iid_opened'
  end
end
