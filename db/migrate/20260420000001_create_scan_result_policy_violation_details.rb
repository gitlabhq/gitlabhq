# frozen_string_literal: true

class CreateScanResultPolicyViolationDetails < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.0'

  def up
    with_lock_retries do
      create_table :scan_result_policy_violation_details, if_not_exists: true do |t|
        t.bigint :scan_result_policy_violation_id, null: false
        t.bigint :project_id, null: false
        t.timestamps_with_timezone null: false
        t.integer :policy_rule_type, limit: 2, null: false
        t.integer :finding_state, limit: 2
        t.text :finding_uuid
        t.text :license_name
        t.text :dependencies, array: true, null: false, default: []
        t.text :commit_shas, array: true, null: false, default: []
        t.jsonb :metadata, null: false, default: {}

        t.index :project_id, name: 'index_scan_result_policy_violation_details_on_project_id'
        t.index :scan_result_policy_violation_id,
          name: 'index_scan_result_policy_violation_details_on_violation_id'
      end
    end

    add_text_limit :scan_result_policy_violation_details, :finding_uuid, 50
    add_text_limit :scan_result_policy_violation_details, :license_name, 255
  end

  def down
    with_lock_retries do
      drop_table :scan_result_policy_violation_details
    end
  end
end
