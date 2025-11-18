# frozen_string_literal: true

class ChangeSecurityFindingsUuidsAllowNullForSecurityPolicyDismissals < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  disable_ddl_transaction!

  def up
    add_not_null_constraint :security_policy_dismissals, :security_findings_uuids
  end

  def down
    remove_not_null_constraint :security_policy_dismissals, :security_findings_uuids
  end
end
