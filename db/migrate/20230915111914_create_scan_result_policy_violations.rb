# frozen_string_literal: true

class CreateScanResultPolicyViolations < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    create_table :scan_result_policy_violations do |t|
      t.bigint :scan_result_policy_id,
        index: false,
        null: false

      t.bigint :merge_request_id,
        index: { name: 'index_scan_result_policy_violations_on_merge_request_id' },
        null: false

      t.bigint :project_id,
        index: { name: 'index_scan_result_policy_violations_on_project_id' },
        null: false

      t.timestamps_with_timezone null: false
    end

    add_index(:scan_result_policy_violations,
      %i[scan_result_policy_id merge_request_id],
      unique: true,
      name: 'index_scan_result_policy_violations_on_policy_and_merge_request')
  end

  def down
    drop_table :scan_result_policy_violations
  end
end
