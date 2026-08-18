# frozen_string_literal: true

class CreateGovernPolicyEnforcements < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def change
    create_table :govern_policy_enforcements do |t|
      t.bigint :organization_id, null: false
      t.references :govern_policy, null: false, index: true, foreign_key: { on_delete: :cascade }
      t.bigint :project_id
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :last_evaluated_at
      t.integer :state, limit: 2, null: false, default: 0

      t.index [:organization_id, :govern_policy_id, :project_id], unique: true,
        where: 'project_id IS NOT NULL',
        name: 'unique_govern_policy_enforcements_org_policy_and_project'
      t.index :organization_id, name: 'index_govern_policy_enforcements_on_organization_id'
      t.index :project_id, name: 'index_govern_policy_enforcements_on_project_id'
    end
  end
end
