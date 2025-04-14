# frozen_string_literal: true

class DropMergeRequestDiffCommitsb5377a7a34 < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.11'
  disable_ddl_transaction!

  TABLE = 'merge_request_diff_commits'
  PARTITIONED_TABLE = 'merge_request_diff_commits_b5377a7a34'

  def up
    return unless Gitlab::Database::PostgresPartitionedTable.find_by_name_in_current_schema(PARTITIONED_TABLE)

    Gitlab::Database::PostgresPartitionedTable.each_partition(PARTITIONED_TABLE) do |partition|
      with_lock_retries do
        execute(<<~SQL)
          ALTER TABLE #{connection.quote_table_name(PARTITIONED_TABLE)}
          DETACH PARTITION #{connection.quote_table_name(partition.identifier)};
          DROP TABLE #{connection.quote_table_name(partition.identifier)};
        SQL
      end
    end

    drop_partitioned_table_for(TABLE)
  end

  def down
    partitioning_column = find_column_definition(TABLE, 'merge_request_diff_id')
    primary_key = %w[merge_request_diff_id relative_order]
    primary_key_objects = connection.columns(TABLE).select { |column| primary_key.include?(column.name) }

    create_range_id_partitioned_copy(
      TABLE,
      PARTITIONED_TABLE,
      partitioning_column,
      primary_key_objects
    )

    add_column PARTITIONED_TABLE, :project_id, :bigint
  end
end
