# frozen_string_literal: true

class ScheduleIndexRemovalForCiBuildsMetadata < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  TABLE_NAME = :ci_builds_metadata
  INDEX_NAME = :index_ci_builds_metadata_on_build_id

  def up
    prepare_async_index_removal(TABLE_NAME, :build_id, name: INDEX_NAME)
  end

  def down
    unprepare_async_index(TABLE_NAME, :build_id, name: INDEX_NAME)
  end
end
