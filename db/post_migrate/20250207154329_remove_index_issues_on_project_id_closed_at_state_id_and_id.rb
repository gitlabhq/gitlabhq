# frozen_string_literal: true

class RemoveIndexIssuesOnProjectIdClosedAtStateIdAndId < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  INDEX_NAME = 'index_issues_on_project_id_closed_at_state_id_and_id'

  def up
    remove_concurrent_index_by_name(:issues, INDEX_NAME)
  end

  def down
    add_concurrent_index(:issues, [:project_id, :closed_at, :state_id, :id], name: INDEX_NAME)
  end
end
