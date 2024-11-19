# frozen_string_literal: true

class AddIndexApprovalPolicyRulesOnSecurityPolicyAndId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  INDEX_NAME = :idx_approval_policy_rules_security_policy_id_id
  TABLE_NAME = :approval_policy_rules

  def up
    add_concurrent_index(TABLE_NAME, %i[security_policy_id id], name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
