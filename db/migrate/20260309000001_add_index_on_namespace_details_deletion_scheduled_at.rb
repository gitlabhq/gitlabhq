# frozen_string_literal: true

class AddIndexOnNamespaceDetailsDeletionScheduledAt < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.10'

  INDEX_NAME = 'index_namespace_details_on_id_and_deletion_scheduled_at'

  def up
    add_concurrent_index :namespace_details, [:namespace_id, :deletion_scheduled_at],
      where: 'deletion_scheduled_at IS NOT NULL',
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :namespace_details, INDEX_NAME
  end
end
