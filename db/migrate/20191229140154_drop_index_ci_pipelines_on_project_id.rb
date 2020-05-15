# frozen_string_literal: true

class DropIndexCiPipelinesOnProjectId < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :ci_pipelines, 'index_ci_pipelines_on_project_id'

    # extra (duplicate) index that already existed on some installs
    remove_concurrent_index_by_name :ci_pipelines, 'ci_pipelines_project_id_idx'
  end

  def down
    add_concurrent_index :ci_pipelines, :project_id, name: 'index_ci_pipelines_on_project_id'
  end
end
