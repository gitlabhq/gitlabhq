# frozen_string_literal: true

class DropMergeRequestDiffFilesPartition < Gitlab::Database::Migration[2.2]
  Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.9'
  disable_ddl_transaction!

  def up
    drop_partitioned_table_for('merge_request_diff_files')
  end

  def down
    partition_table_by_int_range(
      'merge_request_diff_files',
      'merge_request_diff_id',
      partition_size: 200_000_000,
      primary_key: %w[merge_request_diff_id relative_order]
    )

    add_column :merge_request_diff_files_99208b8fac, :project_id, :bigint
  end
end
