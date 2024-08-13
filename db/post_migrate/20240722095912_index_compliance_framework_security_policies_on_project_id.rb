# frozen_string_literal: true

class IndexComplianceFrameworkSecurityPoliciesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  disable_ddl_transaction!

  INDEX_NAME = 'index_compliance_framework_security_policies_on_project_id'

  def up
    add_concurrent_index :compliance_framework_security_policies, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :compliance_framework_security_policies, INDEX_NAME
  end
end
