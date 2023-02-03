# frozen_string_literal: true

class CreateScanResultPolicies < Gitlab::Database::Migration[2.1]
  INDEX_NAME = "index_scan_result_policies_on_policy_configuration_id"

  def change
    create_table :scan_result_policies do |t|
      t.references :security_orchestration_policy_configuration,
                   null: false,
                   foreign_key: { on_delete: :cascade },
                   index: { name: INDEX_NAME }

      t.timestamps_with_timezone null: false
      t.integer :orchestration_policy_idx, limit: 2, null: false
      t.text :license_states, array: true, default: []
    end
  end
end
