# frozen_string_literal: true

class AddBuildIdToAnalyzerProjectStatuses < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '18.0'

  INDEX_NAME = "index_analyzer_project_statuses_build_id"

  def up
    add_column :analyzer_project_statuses, :build_id, :bigint, null: true
    add_concurrent_index :analyzer_project_statuses, :build_id, name: INDEX_NAME
  end

  def down
    remove_column :analyzer_project_statuses, :build_id
    remove_concurrent_index_by_name :analyzer_project_statuses, INDEX_NAME
  end
end
