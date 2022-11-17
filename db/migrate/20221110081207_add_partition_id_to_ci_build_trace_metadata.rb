# frozen_string_literal: true

class AddPartitionIdToCiBuildTraceMetadata < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :ci_build_trace_metadata, :partition_id, :bigint, default: 100, null: false
  end
end
