# frozen_string_literal: true

class SupportPartitionQueryInLooseFkTable < Gitlab::Database::Migration[1.0]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_loose_foreign_keys_deleted_records_for_partitioned_query'

  def up
    add_concurrent_partitioned_index :loose_foreign_keys_deleted_records,
      %I[partition fully_qualified_table_name consume_after id],
      where: 'status = 1',
      name: INDEX_NAME
  end

  def down
    remove_concurrent_partitioned_index_by_name :loose_foreign_keys_deleted_records, INDEX_NAME
  end
end
