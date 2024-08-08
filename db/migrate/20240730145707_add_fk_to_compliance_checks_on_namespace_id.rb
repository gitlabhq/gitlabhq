# frozen_string_literal: true

class AddFkToComplianceChecksOnNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :compliance_checks, :namespaces, column: :namespace_id, reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :compliance_checks, column: :namespace_id, reverse_lock_order: true
    end
  end
end
