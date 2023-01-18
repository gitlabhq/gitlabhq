# frozen_string_literal: true

class RemoveTempIndexForProjectStatisticsUploadSizeMigration < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'tmp_index_project_statistics_uploads_size'
  TABLE_NAME = 'project_statistics'
  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :project_statistics, INDEX_NAME
  end

  def down
    add_concurrent_index :project_statistics, [:project_id],
      name: INDEX_NAME,
      where: "uploads_size <> 0"
  end
end
