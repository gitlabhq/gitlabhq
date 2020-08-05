# frozen_string_literal: true

class AddFkToMetricsTargetProjectId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:merge_request_metrics, :target_project_id)
    add_concurrent_foreign_key(:merge_request_metrics, :projects, column: :target_project_id, on_delete: :cascade)
  end

  def down
    remove_foreign_key(:merge_request_metrics, column: :target_project_id)
    remove_concurrent_index(:merge_request_metrics, :target_project_id)
  end
end
