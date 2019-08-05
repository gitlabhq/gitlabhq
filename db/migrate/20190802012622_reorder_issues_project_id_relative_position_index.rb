# frozen_string_literal: true

class ReorderIssuesProjectIdRelativePositionIndex < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  OLD_INDEX_NAME = 'index_issues_on_project_id_and_state_and_rel_position_and_id'
  NEW_INDEX_NAME = 'index_issues_on_project_id_and_rel_position_and_state_and_id'

  def up
    add_concurrent_index :issues, [:project_id, :relative_position, :state, :id], order: { id: :desc }, name: NEW_INDEX_NAME

    remove_concurrent_index_by_name :issues, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :issues, [:project_id, :state, :relative_position, :id], order: { id: :desc }, name: OLD_INDEX_NAME

    remove_concurrent_index_by_name :issues, NEW_INDEX_NAME
  end
end
