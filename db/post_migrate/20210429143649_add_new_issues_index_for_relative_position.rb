# frozen_string_literal: true

class AddNewIssuesIndexForRelativePosition < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'idx_issues_on_project_id_and_rel_asc_and_id'

  def up
    add_concurrent_index :issues, [:project_id, :relative_position, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name(:issues, INDEX_NAME)
  end
end
