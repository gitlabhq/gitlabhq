# frozen_string_literal: true

class CreateGovernPolicies < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def change
    create_table :govern_policies do |t|
      t.bigint :organization_id, null: false
      t.bigint :namespace_id, null: false, index: true
      t.timestamps_with_timezone null: false
      t.integer :version, null: false, default: 1
      t.integer :trigger_type, limit: 2, null: false
      t.integer :mode, limit: 2, null: false, default: 2
      t.integer :lifecycle_state, limit: 2, null: false, default: 0
      t.text :name, null: false, limit: 255
      t.text :description, limit: 4096
      t.text :scope_rego, limit: 4096
      t.jsonb :policy_scope
      t.jsonb :rules, null: false, default: []
      t.jsonb :actions, null: false, default: []

      t.index [:organization_id, :namespace_id, :name], unique: true,
        name: 'unique_govern_policies_organization_id_namespace_id_and_name'
    end
  end
end
