# frozen_string_literal: true

class CreateMergeRequestApprovalMetrics < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def up
    create_table :merge_request_approval_metrics, id: false do |t|
      t.references :merge_request, primary_key: true, index: true,
        foreign_key: { on_delete: :cascade }
      t.datetime_with_timezone :last_approved_at, null: false
      t.bigint :target_project_id, null: false
      t.index [:target_project_id, :merge_request_id], unique: true,
        name: :index_mr_approval_metrics_on_project_id_and_mr_id
    end

    execute 'DROP SEQUENCE IF EXISTS merge_request_approval_metrics_merge_request_id_seq CASCADE'
  end

  def down
    drop_table :merge_request_approval_metrics
  end
end
