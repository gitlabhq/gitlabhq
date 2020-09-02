# frozen_string_literal: true

class AddTmpIndexToTargetProjectId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  TMP_INDEX_NAME = 'tmp_index_on_mr_metrics_target_project_id_null'
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_request_metrics, :id, where: 'target_project_id IS NULL', name: TMP_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :merge_request_metrics, name: TMP_INDEX_NAME
  end
end
