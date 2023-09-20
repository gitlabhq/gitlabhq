# frozen_string_literal: true

class AddTempIndexForProjectStatisticsUpdatedAt < Gitlab::Database::Migration[2.1]
  INDEX_PROJECT_STATISTICS_UPDATED_AT = 'tmp_index_project_statistics_updated_at'

  disable_ddl_transaction!

  def up
    # Temporary index is to be used to trigger a refresh of project_statistics repository_size
    add_concurrent_index :project_statistics, [:project_id, :updated_at],
      name: INDEX_PROJECT_STATISTICS_UPDATED_AT,
      where: "repository_size > 0"
  end

  def down
    remove_concurrent_index_by_name :project_statistics, INDEX_PROJECT_STATISTICS_UPDATED_AT
  end
end
