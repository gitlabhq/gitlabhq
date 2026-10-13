# frozen_string_literal: true

class AddIndexToNamespaceDetailsOnDeletionScheduledAt < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.4'

  INDEX_NAME = 'index_namespace_details_on_deletion_scheduled_at'

  def up
    add_concurrent_index :namespace_details, :deletion_scheduled_at, name: INDEX_NAME,
      where: 'deletion_scheduled_at IS NOT NULL'
  end

  def down
    remove_concurrent_index_by_name :namespace_details, INDEX_NAME
  end
end
