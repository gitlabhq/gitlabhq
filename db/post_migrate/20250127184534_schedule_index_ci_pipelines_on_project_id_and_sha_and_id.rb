# frozen_string_literal: true

class ScheduleIndexCiPipelinesOnProjectIdAndShaAndId < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  TABLE_NAME = :ci_pipelines
  COLUMN_NAMES = [:project_id, :sha, :id]
  INDEX_NAME = 'ci_pipelines_on_project_id_and_sha_and_id'

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/516073
  def up
    prepare_async_index(TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME)
  end

  def down
    unprepare_async_index(TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME)
  end
end
