# frozen_string_literal: true

class AddFkForPartitionedUploadsNamespaceId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  milestone '17.11'

  disable_ddl_transaction!

  def up
    add_concurrent_partitioned_foreign_key :uploads_9ba88c4165, :namespaces, column: :namespace_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :uploads_9ba88c4165, column: :namespace_id
    end
  end
end
