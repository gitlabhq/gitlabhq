# frozen_string_literal: true

class AddApprovalPolicyRuleIdToSoftwareLicensePolicies < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def up
    add_column :software_license_policies, :approval_policy_rule_id, :bigint
  end

  def down
    remove_column :software_license_policies, :approval_policy_rule_id
  end
end
