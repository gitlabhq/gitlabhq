# frozen_string_literal: true

class RemoveTmpIndexProjectStatisticsUpdatedAtSync < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_index_project_statistics_updated_at'
  COLUMNS = %i[project_id updated_at]

  def up
    remove_concurrent_index_by_name :project_statistics, name: INDEX_NAME
  end

  def down
    add_concurrent_index :project_statistics, COLUMNS, name: INDEX_NAME, where: 'repository_size > 0'
  end
end
