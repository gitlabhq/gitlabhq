# frozen_string_literal: true

class AddSecurityPolicyDismissalsSecurityPolicyOnDeleteNullifyForeignKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.6'

  FOREIGN_KEY_NAME = 'fk_c2379f1e97_new'

  def up
    add_concurrent_foreign_key :security_policy_dismissals, :security_policies,
      column: :security_policy_id,
      on_delete: :nullify,
      name: FOREIGN_KEY_NAME
  end

  def down
    remove_foreign_key_if_exists(:security_policy_dismissals, column: :security_policy_id, on_delete: :nullify,
      name: FOREIGN_KEY_NAME)
  end
end
