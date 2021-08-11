# frozen_string_literal: true

class AddIndexIssuesOnProjectIdAndStateIdAndCreatedAtAndId < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_issues_on_project_id_and_state_id_and_created_at_and_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :issues, [:project_id, :state_id, :created_at, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :issues, INDEX_NAME
  end
end
