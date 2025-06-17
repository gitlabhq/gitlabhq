# frozen_string_literal: true

class ScheduleIndexCiPipelinesOnProjectIdAndShaAndId < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  TABLE_NAME = :ci_pipelines
  COLUMN_NAMES = [:project_id, :sha, :id]
  INDEX_NAME = 'ci_pipelines_on_project_id_and_sha_and_id'

  def up
    # no-op
  end

  def down
    # no-op
  end
end
