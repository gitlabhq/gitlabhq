# frozen_string_literal: true

class AddTargetProjectAndSourceBranchIndexToMergeRequest < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_merge_requests_on_target_project_id_and_source_branch'

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_requests, [:target_project_id, :source_branch], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :epic_issues, INDEX_NAME
  end
end
