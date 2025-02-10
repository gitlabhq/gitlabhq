# frozen_string_literal: true

class IndexMergeRequestPredictionsOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  INDEX_NAME = 'index_merge_request_predictions_on_project_id'

  def up
    add_concurrent_index :merge_request_predictions, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :merge_request_predictions, INDEX_NAME
  end
end
