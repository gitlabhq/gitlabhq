# frozen_string_literal: true

class CreateMergeRequestsComplianceViolations < Gitlab::Database::Migration[1.0]
  def change
    create_table :merge_requests_compliance_violations do |t|
      t.bigint :violating_user_id, null: false
      t.bigint :merge_request_id, null: false
      t.integer :reason, limit: 2, null: false
      t.index :violating_user_id
      t.index [:merge_request_id, :violating_user_id, :reason], unique: true, name: 'index_merge_requests_compliance_violations_unique_columns'
    end
  end
end
