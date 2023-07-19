# frozen_string_literal: true

class DropCiBuildTraceMetadataPartitionIdDefault < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  enable_lock_retries!

  TABLE_NAME = :ci_build_trace_metadata
  COLUMN_NAME = :partition_id

  def up
    change_column_default(TABLE_NAME, COLUMN_NAME, from: 100, to: nil) if should_run?
  end

  def down
    change_column_default(TABLE_NAME, COLUMN_NAME, from: nil, to: 100) if should_run?
  end

  private

  def should_run?
    can_execute_on?(TABLE_NAME)
  end
end
