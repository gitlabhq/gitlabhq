# frozen_string_literal: true

class AddDismissalTypesIndexToSecurityPolicyDismissals < Gitlab::Database::Migration[2.3]
  milestone '18.4'
  disable_ddl_transaction!

  DISMISSAL_TYPES_INDEX_NAME = 'index_security_policy_dismissals_on_dismissal_types'

  def up
    add_concurrent_index :security_policy_dismissals, :dismissal_types, using: :gin, name: DISMISSAL_TYPES_INDEX_NAME
  end

  def down
    remove_concurrent_index :security_policy_dismissals, :dismissal_types, name: DISMISSAL_TYPES_INDEX_NAME
  end
end
