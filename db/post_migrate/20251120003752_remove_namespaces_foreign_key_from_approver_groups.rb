# frozen_string_literal: true

class RemoveNamespacesForeignKeyFromApproverGroups < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :approver_groups, :namespaces,
        column: :group_id, reverse_lock_order: true
    end
  end

  def down
    add_concurrent_foreign_key :approver_groups, :namespaces,
      column: :group_id, on_delete: :cascade, name: 'fk_rails_1cdcbd7723',
      if_not_exists: true
  end
end
