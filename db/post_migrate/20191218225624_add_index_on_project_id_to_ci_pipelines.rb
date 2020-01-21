# frozen_string_literal: true

class AddIndexOnProjectIdToCiPipelines < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_ci_pipelines_on_project_id_and_id_desc'

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_pipelines, [:project_id, :id], name: INDEX_NAME, order: { id: :desc }
  end

  def down
    remove_concurrent_index :ci_pipelines, [:project_id, :id], name: INDEX_NAME, order: { id: :desc }
  end
end
