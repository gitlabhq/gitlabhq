# frozen_string_literal: true

class AddForeignKeyConstraintOnBulkImportBatchTrackersNamespaceId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  TABLE_NAME = 'bulk_import_batch_trackers'

  def up
    add_concurrent_foreign_key TABLE_NAME,
      :namespaces,
      column: :namespace_id,
      on_delete: :cascade,
      validate: false
  end

  def down
    remove_foreign_key_if_exists TABLE_NAME, :namespaces, column: :namespace_id
  end
end
