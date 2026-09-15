# frozen_string_literal: true

class CreateGovernPolicyViolations < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    create_table :govern_policy_violations do |t|
      t.bigint :organization_id, null: false, index: true
      t.references :govern_policy_evaluation, null: false, foreign_key: { on_delete: :cascade },
        index: { name: 'index_govern_policy_violations_on_evaluation_id' }
      t.bigint :govern_policy_id, null: false
      t.timestamps_with_timezone null: false
      t.jsonb :details

      t.index [:govern_policy_id, :created_at],
        name: 'index_govern_policy_violations_on_policy_and_created_at'
    end
  end
end
