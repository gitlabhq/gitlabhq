# frozen_string_literal: true

class RemoveRedundantPipelinesIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :ci_pipelines, :index_ci_pipelines_on_project_id_and_created_at
  end

  def down
    add_concurrent_index :ci_pipelines, [:project_id, :created_at]
  end
end
