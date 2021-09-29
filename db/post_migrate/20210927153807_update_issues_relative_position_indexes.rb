# frozen_string_literal: true

class UpdateIssuesRelativePositionIndexes < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  RELATIVE_POSITION_INDEX_NAME = 'idx_issues_on_project_id_and_rel_asc_and_id'
  RELATIVE_POSITION_STATE_INDEX_NAME = 'idx_issues_on_project_id_and_rel_position_and_state_id_and_id'

  NEW_RELATIVE_POSITION_STATE_INDEX_NAME = 'idx_issues_on_project_id_and_rel_position_and_id_and_state_id'

  def up
    add_concurrent_index :issues, [:project_id, :relative_position, :id, :state_id], name: NEW_RELATIVE_POSITION_STATE_INDEX_NAME

    remove_concurrent_index_by_name :issues, RELATIVE_POSITION_INDEX_NAME
    remove_concurrent_index_by_name :issues, RELATIVE_POSITION_STATE_INDEX_NAME
  end

  def down
    add_concurrent_index :issues, [:project_id, :relative_position, :state_id, :id], order: { id: :desc }, name: RELATIVE_POSITION_STATE_INDEX_NAME
    add_concurrent_index :issues, [:project_id, :relative_position, :id], name: RELATIVE_POSITION_INDEX_NAME

    remove_concurrent_index_by_name :issues, NEW_RELATIVE_POSITION_STATE_INDEX_NAME
  end
end
