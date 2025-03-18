# frozen_string_literal: true

class CreateMergeRequestsApprovalRulesApproverUsers < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    create_table :merge_requests_approval_rules_approver_users do |t|
      t.bigint :approval_rule_id, null: false
      t.bigint :user_id, null: false
      t.bigint :project_id, null: true
      t.bigint :group_id, null: true
      t.index :user_id
      t.index :project_id, name: 'index_mrs_approval_rules_approver_users_on_project_id'
      t.index :group_id

      t.timestamps_with_timezone null: false
    end

    add_index(
      :merge_requests_approval_rules_approver_users,
      %i[approval_rule_id user_id],
      unique: true,
      name: 'index_mrs_ars_users_on_ar_id_and_user_id'
    )
  end
end
