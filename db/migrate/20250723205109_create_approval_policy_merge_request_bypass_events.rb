# frozen_string_literal: true

class CreateApprovalPolicyMergeRequestBypassEvents < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def up
    create_table :approval_policy_merge_request_bypass_events do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.bigint :merge_request_id, null: false,
        index: { name: 'index_approval_policy_merge_request_bypass_events_on_mr_id' }
      t.bigint :security_policy_id, null: false,
        index: { name: 'index_approval_policy_merge_request_bypass_events_on_policy_id' }
      t.bigint :user_id, null: true,
        index: { name: 'index_approval_policy_merge_request_bypass_events_on_user_id' }

      t.timestamps_with_timezone null: false

      # rubocop:disable Migration/AddLimitToTextColumns -- combined with check constraint
      t.text :reason, null: false
      t.check_constraint "length(trim(reason)) BETWEEN 1 AND 1024",
        name: check_constraint_name(:approval_policy_merge_request_bypass_events, :reason, 'length_between_1_and_1024')
      # rubocop:enable Migration/AddLimitToTextColumns
    end

    add_index :approval_policy_merge_request_bypass_events,
      [:project_id, :merge_request_id, :security_policy_id],
      unique: true,
      name: 'idx_approval_policy_mr_bypass_events_on_project_mr_policy'
  end

  def down
    drop_table :approval_policy_merge_request_bypass_events
  end
end
