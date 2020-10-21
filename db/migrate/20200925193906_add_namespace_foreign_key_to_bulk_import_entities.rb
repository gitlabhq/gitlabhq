# frozen_string_literal: true

class AddNamespaceForeignKeyToBulkImportEntities < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :bulk_import_entities, :namespaces, column: :namespace_id
  end

  def down
    with_lock_retries do
      remove_foreign_key :bulk_import_entities, column: :namespace_id
    end
  end
end
