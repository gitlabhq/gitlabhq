# frozen_string_literal: true

class AddFkAndIndexForSecurityPolicyOnSeverityOverrides < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.10'

  INDEX_NAME = 'index_vuln_severity_overrides_on_security_policy_id'

  def up
    # No FK constraint because security_policies is on gitlab_main_org
    # and vulnerability_severity_overrides is on gitlab_sec
    add_concurrent_index :vulnerability_severity_overrides, :security_policy_id,
      name: INDEX_NAME, where: 'security_policy_id IS NOT NULL'
  end

  def down
    remove_concurrent_index_by_name :vulnerability_severity_overrides, INDEX_NAME
  end
end
