# frozen_string_literal: true

class ScheduleIndexRemovalCiPipelinesOnProjectIdAndShaAndId < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.1'
  disable_ddl_transaction!

  TABLE_NAME = :ci_pipelines
  INDEX_NAME = :ci_pipelines_on_project_id_and_sha_and_id
  COLUMN_NAMES = [:project_id, :sha, :id]

  def up
    prepare_async_index_removal(TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME)
  end

  def down
    unprepare_async_index(TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME)
  end
end
