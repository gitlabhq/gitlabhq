# frozen_string_literal: true

class RemoveObsoleteNamespaceDeletionColumns < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.3'

  TABLE_NAME = :namespaces
  FK_NAME = 'fk_9ff61b4c22'
  INDEX_MARKED_FOR_DELETION_AT = 'index_namespaces_on_marked_for_deletion_at'
  INDEX_MARKED_FOR_DELETION_BY_USER_ID = 'index_namespaces_on_marked_for_deletion_by_user_id'

  def up
    # Remove FK first (references users), then indexes, then columns.
    # namespaces is a high-traffic table so wrap FK removal in with_lock_retries.
    with_lock_retries do
      remove_foreign_key_if_exists(TABLE_NAME, :users, name: FK_NAME, reverse_lock_order: true)
    end

    remove_concurrent_index_by_name(TABLE_NAME, INDEX_MARKED_FOR_DELETION_AT)
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_MARKED_FOR_DELETION_BY_USER_ID)

    remove_column(TABLE_NAME, :marked_for_deletion_at, if_exists: true)
    remove_column(TABLE_NAME, :marked_for_deletion_by_user_id, if_exists: true)
  end

  def down
    # no-op: columns, indexes, and FK are not used by the application
  end
end
