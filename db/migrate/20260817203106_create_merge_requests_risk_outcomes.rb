# frozen_string_literal: true

class CreateMergeRequestsRiskOutcomes < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  TABLE_NAME = :merge_requests_risk_outcomes
  ASSESSMENT_INDEX_NAME = 'idx_mr_risk_outcomes_on_assessment_and_signal'
  PROJECT_INDEX_NAME = 'index_merge_requests_risk_outcomes_on_project_id'

  def up
    create_table TABLE_NAME, if_not_exists: true do |t|
      t.bigint :risk_assessment_id, null: false
      t.bigint :project_id, null: false
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :observed_at, null: false
      t.integer :signal_type, limit: 2, null: false
      t.integer :confidence, limit: 2, null: false
      t.jsonb :evidence, null: false, default: {}

      # One outcome per signal type per assessment: observing the same revert
      # twice must not double count it.
      t.index [:risk_assessment_id, :signal_type], unique: true, name: ASSESSMENT_INDEX_NAME
      t.index :project_id, name: PROJECT_INDEX_NAME
    end

    add_concurrent_foreign_key TABLE_NAME, :merge_requests_risk_assessments,
      column: :risk_assessment_id, on_delete: :cascade
  end

  def down
    drop_table TABLE_NAME
  end
end
