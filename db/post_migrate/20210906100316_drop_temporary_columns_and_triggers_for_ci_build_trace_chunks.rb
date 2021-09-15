# frozen_string_literal: true

class DropTemporaryColumnsAndTriggersForCiBuildTraceChunks < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  TABLE = 'ci_build_trace_chunks'
  COLUMN = 'build_id'

  # rubocop:disable Migration/WithLockRetriesDisallowedMethod
  def up
    with_lock_retries do
      cleanup_conversion_of_integer_to_bigint(TABLE, COLUMN)
    end
  end
  # rubocop:enable Migration/WithLockRetriesDisallowedMethod

  def down
    restore_conversion_of_integer_to_bigint(TABLE, COLUMN)
  end
end
