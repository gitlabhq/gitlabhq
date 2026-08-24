# frozen_string_literal: true

class CreateGovernPolicyEvaluations < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    create_table :govern_policy_evaluations do |t|
      t.bigint :organization_id, null: false
      t.references :govern_policy, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.bigint :project_id, index: true
      t.bigint :environment_id
      t.bigint :user_id
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :evaluated_at, null: false
      t.integer :policy_version, null: false
      t.integer :trigger_type, limit: 2, null: false
      t.integer :mode, limit: 2, null: false
      t.integer :verdict, limit: 2, null: false

      t.index [:govern_policy_id, :evaluated_at],
        name: 'index_govern_policy_evaluations_on_policy_and_evaluated_at'
      t.index [:organization_id, :evaluated_at],
        name: 'index_govern_policy_evaluations_on_org_and_evaluated_at'
    end
  end
end
