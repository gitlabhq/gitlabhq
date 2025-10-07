# frozen_string_literal: true

class AddSecurityFindingsUuidsIndexToSecurityPolicyDismissals < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  disable_ddl_transaction!

  INDEX_NAME = 'idx_security_policy_dismissals_project_findings_uuids'

  def up
    add_concurrent_index :security_policy_dismissals, :security_findings_uuids, using: :gin, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :security_policy_dismissals, :security_findings_uuids, name: INDEX_NAME
  end
end
