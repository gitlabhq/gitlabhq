# frozen_string_literal: true

class AddIndexOnStatusToMergeTrains < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_for_status_per_branch_per_project'

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_trains, [:target_project_id, :target_branch, :status], name: INDEX_NAME
    remove_concurrent_index :merge_trains, :target_project_id
  end

  def down
    add_concurrent_index :merge_trains, :target_project_id
    remove_concurrent_index :merge_trains, [:target_project_id, :target_branch, :status], name: INDEX_NAME
  end
end
