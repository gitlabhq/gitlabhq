# frozen_string_literal: true

class CreateMergeRequestsApprovalRulesMergeRequests < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    create_table :merge_requests_approval_rules_merge_requests do |t| # Migration/EnsureFactoryForTable false positive
      t.bigint :approval_rule_id, null: false
      t.bigint :merge_request_id, null: false
      t.bigint :project_id, null: false
      t.index :merge_request_id, name: 'index_mrs_approval_rules_mrs_on_mr_id'
      t.index :project_id, name: 'index_mrs_approval_rules_mrs_on_project_id'
      t.timestamps_with_timezone null: false
    end

    add_index(
      :merge_requests_approval_rules_merge_requests,
      %i[approval_rule_id merge_request_id],
      unique: true,
      name: 'index_mrs_ars_mrs_on_ar_id_and_mr_id'
    )
  end
end
