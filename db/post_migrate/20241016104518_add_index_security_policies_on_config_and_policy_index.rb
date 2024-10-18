# frozen_string_literal: true

class AddIndexSecurityPoliciesOnConfigAndPolicyIndex < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  INDEX_NAME = :idx_security_policies_config_id_policy_index
  TABLE_NAME = :security_policies

  def up
    add_concurrent_index(TABLE_NAME, %i[security_orchestration_policy_configuration_id policy_index], name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
