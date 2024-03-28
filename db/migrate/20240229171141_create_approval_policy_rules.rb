# frozen_string_literal: true

class CreateApprovalPolicyRules < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  INDEX_NAME = "index_approval_policy_rules_on_unique_policy_rule_index"

  def change
    create_table :approval_policy_rules do |t|
      t.references :security_policy,
        null: false,
        foreign_key: { on_delete: :cascade },
        index: false
      t.timestamps_with_timezone null: false
      t.integer :rule_index, limit: 2, null: false
      t.integer :type, limit: 2, null: false
      t.jsonb :content, default: {}, null: false
    end

    add_index(
      :approval_policy_rules,
      %i[security_policy_id rule_index],
      unique: true,
      name: INDEX_NAME)
  end
end
