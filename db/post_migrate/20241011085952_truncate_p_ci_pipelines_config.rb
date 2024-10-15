# frozen_string_literal: true

class TruncatePCiPipelinesConfig < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  TABLE_NAME = :p_ci_pipelines_config

  def up
    partitions = Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME).map(&:identifier)
    truncate_tables!(*partitions)
  end

  def down
    # no-op
  end
end
