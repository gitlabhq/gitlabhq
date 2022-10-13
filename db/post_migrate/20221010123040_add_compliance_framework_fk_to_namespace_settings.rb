# frozen_string_literal: true

class AddComplianceFrameworkFkToNamespaceSettings < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :namespace_settings, :compliance_management_frameworks,
                               column: :default_compliance_framework_id, on_delete: :nullify, reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key :namespace_settings, column: :default_compliance_framework_id
    end
  end
end
