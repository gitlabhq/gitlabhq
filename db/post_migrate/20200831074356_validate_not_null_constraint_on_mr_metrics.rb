# frozen_string_literal: true

class ValidateNotNullConstraintOnMrMetrics < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  TMP_INDEX_NAME = 'tmp_index_on_mr_metrics_target_project_id_null'
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    validate_not_null_constraint :merge_request_metrics, :target_project_id

    remove_concurrent_index_by_name :merge_request_metrics, name: TMP_INDEX_NAME
  end

  def down
    add_concurrent_index :merge_request_metrics, :id, where: 'target_project_id IS NULL', name: TMP_INDEX_NAME
  end
end
