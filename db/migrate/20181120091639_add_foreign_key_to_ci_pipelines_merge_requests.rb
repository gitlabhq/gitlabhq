# frozen_string_literal: true

class AddForeignKeyToCiPipelinesMergeRequests < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_pipelines, :merge_request_id
    add_concurrent_foreign_key :ci_pipelines, :merge_requests, column: :merge_request_id, on_delete: :cascade
  end

  def down
    if foreign_key_exists?(:ci_pipelines, :merge_requests, column: :merge_request_id)
      remove_foreign_key :ci_pipelines, :merge_requests
    end

    remove_concurrent_index :ci_pipelines, :merge_request_id
  end
end
