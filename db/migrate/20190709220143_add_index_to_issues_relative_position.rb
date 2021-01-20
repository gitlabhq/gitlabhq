# frozen_string_literal: true

class AddIndexToIssuesRelativePosition < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'index_issues_on_project_id_and_state_and_rel_position_and_id'

  def up
    add_concurrent_index :issues, [:project_id, :state, :relative_position, :id], order: { id: :desc }, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :issues, INDEX_NAME
  end
end
