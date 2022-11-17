# frozen_string_literal: true

class AddTempIndexForProjectStatisticsUploadSizeMigration < Gitlab::Database::Migration[2.0]
  INDEX_PROJECT_STATSISTICS_UPLOADS_SIZE = 'tmp_index_project_statistics_uploads_size'

  disable_ddl_transaction!

  def up
    # Temporary index is to be used to trigger refresh for all project_statistics with
    # upload_size <> 0
    add_concurrent_index :project_statistics, [:project_id],
      name: INDEX_PROJECT_STATSISTICS_UPLOADS_SIZE,
      where: "uploads_size <> 0"
  end

  def down
    remove_concurrent_index_by_name :project_statistics, INDEX_PROJECT_STATSISTICS_UPLOADS_SIZE
  end
end
