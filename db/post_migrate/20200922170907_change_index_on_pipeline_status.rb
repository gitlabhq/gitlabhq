# frozen_string_literal: true

class ChangeIndexOnPipelineStatus < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  OLD_INDEX_NAME = 'index_ci_pipelines_on_status'
  NEW_INDEX_NAME = 'index_ci_pipelines_on_status_and_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_pipelines, [:status, :id], name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :ci_pipelines, name: OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :ci_pipelines, :status, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :ci_pipelines, name: NEW_INDEX_NAME
  end
end
