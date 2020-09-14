# frozen_string_literal: true

class RemoveOldMergeRequestApiIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index :merge_requests, [:target_project_id, :created_at], name: :index_merge_requests_target_project_id_created_at
  end

  def down
    add_concurrent_index :merge_requests, [:target_project_id, :created_at], name: :index_merge_requests_target_project_id_created_at
  end
end
