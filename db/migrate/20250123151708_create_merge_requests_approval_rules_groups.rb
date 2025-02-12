# frozen_string_literal: true

class CreateMergeRequestsApprovalRulesGroups < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    create_table :merge_requests_approval_rules_groups do |t| # -- Migration/EnsureFactoryForTable false positive
      t.bigint :approval_rule_id, null: false
      t.bigint :group_id, null: false
      t.index :group_id
      t.timestamps_with_timezone null: false
    end

    add_index(
      :merge_requests_approval_rules_groups,
      %i[approval_rule_id group_id],
      unique: true,
      name: 'index_mrs_ars_groups_on_ar_id_and_group_id'
    )
  end
end
