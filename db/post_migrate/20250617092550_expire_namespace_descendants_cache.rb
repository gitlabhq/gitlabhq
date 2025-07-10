# frozen_string_literal: true

class ExpireNamespaceDescendantsCache < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '18.2'

  def up
    table = Gitlab::Database::PostgresPartitionedTable.find_by_name_in_current_schema("namespace_descendants")
    table.postgres_partitions.each do |partition|
      partition_name = "#{quote_table_name(partition.schema)}.#{quote_table_name(partition.name)}"
      with_lock_retries do
        execute "UPDATE #{partition_name} SET outdated_at = NOW()"
      end
    end
  end

  def down
    # no-op
  end
end
