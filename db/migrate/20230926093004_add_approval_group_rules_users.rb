# frozen_string_literal: true

class AddApprovalGroupRulesUsers < Gitlab::Database::Migration[2.1]
  INDEX_RULE_USER = 'idx_on_approval_group_rules_users_rule_user'

  def up
    create_table :approval_group_rules_users do |t|
      t.bigint :approval_group_rule_id, null: false
      t.bigint :user_id, null: false, index: true

      t.index [:approval_group_rule_id, :user_id], unique: true, name: INDEX_RULE_USER
    end
  end

  def down
    drop_table :approval_group_rules_users
  end
end
