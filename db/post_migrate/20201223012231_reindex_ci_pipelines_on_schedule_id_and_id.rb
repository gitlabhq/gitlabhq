# frozen_string_literal: true

class ReindexCiPipelinesOnScheduleIdAndId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  OLD_INDEX_NAME = 'index_ci_pipelines_on_pipeline_schedule_id'
  NEW_INDEX_NAME = 'index_ci_pipelines_on_pipeline_schedule_id_and_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_pipelines, [:pipeline_schedule_id, :id], name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :ci_pipelines, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :ci_pipelines, :pipeline_schedule_id, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :ci_pipelines, NEW_INDEX_NAME
  end
end
