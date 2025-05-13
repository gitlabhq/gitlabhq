# frozen_string_literal: true

class TruncateCiBuildTraceMetadataPartition < Gitlab::Database::Migration[2.3]
  milestone '18.0'

  disable_ddl_transaction!

  PARTITION_NAME = 'gitlab_partitions_dynamic.ci_build_trace_metadata_102'

  def up
    return unless Gitlab.com_except_jh?

    truncate_tables!(PARTITION_NAME)
  end

  def down
    # no-op
  end
end
