# frozen_string_literal: true

class CreateDependencyFirewallPolicyRules < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def up
    create_table :dependency_firewall_policy_rules, if_not_exists: true do |t|
      t.bigint :security_policy_id, null: false
      t.bigint :security_policy_management_project_id, null: false
      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false
      t.integer :rule_index, null: false, default: 0
      t.column :type, :smallint, null: false, default: 0
      t.jsonb :content, null: false, default: {}

      t.index :security_policy_management_project_id, name: 'i_dep_fw_rules_pol_mgmt_proj_id'
      t.index [:security_policy_id, :rule_index], unique: true,
        name: 'i_dep_fw_rules_uniq_rule_idx'
    end
  end

  def down
    drop_table :dependency_firewall_policy_rules, if_exists: true
  end
end
