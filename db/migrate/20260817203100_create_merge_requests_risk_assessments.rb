# frozen_string_literal: true

class CreateMergeRequestsRiskAssessments < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  TABLE_NAME = :merge_requests_risk_assessments
  UNIQUE_INDEX_NAME = 'index_merge_requests_risk_assessments_on_merge_request_id'
  PROJECT_INDEX_NAME = 'index_merge_requests_risk_assessments_on_project_id'

  def up
    create_table TABLE_NAME, if_not_exists: true do |t|
      t.bigint :merge_request_id, null: false
      t.bigint :project_id, null: false
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :assessed_at
      t.integer :score, limit: 2
      t.integer :confidence, limit: 2
      t.integer :status, limit: 2, null: false, default: 0
      t.binary :diff_sha, null: false
      t.text :scoring_function_version, limit: 20
      t.text :rationale, limit: 2048
      t.text :domain_tags, array: true, null: false, default: []
      t.text :missing_signals, array: true, null: false, default: []
      t.jsonb :signal_breakdown, null: false, default: []
      t.jsonb :classification, null: false, default: {}

      t.index :merge_request_id, unique: true, name: UNIQUE_INDEX_NAME
      t.index :project_id, name: PROJECT_INDEX_NAME
    end

    add_concurrent_foreign_key TABLE_NAME, :merge_requests, column: :merge_request_id, on_delete: :cascade
  end

  def down
    drop_table TABLE_NAME, if_exists: true
  end
end
