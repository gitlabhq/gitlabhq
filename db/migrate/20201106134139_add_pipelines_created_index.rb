# frozen_string_literal: true

class AddPipelinesCreatedIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  INDEX_NAME = :index_ci_pipelines_on_project_id_and_status_and_created_at

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_pipelines, [:project_id, :status, :created_at], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_pipelines, INDEX_NAME
  end
end
