# frozen_string_literal: true

class AddForeignKeyForNamespaceIdToMemberApprovals < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.9'

  def up
    add_concurrent_foreign_key :member_approvals, :namespaces, column: :member_namespace_id
  end

  def down
    with_lock_retries do
      remove_foreign_key :member_approvals, column: :member_namespace_id
    end
  end
end
