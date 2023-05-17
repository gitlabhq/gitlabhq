# frozen_string_literal: true

class CleanupBigintConversionForMergeRequestMetrics < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!

  TABLE = :merge_request_metrics

  def up
    return unless should_run?

    # rubocop:disable Migration/WithLockRetriesDisallowedMethod
    with_lock_retries do
      cleanup_conversion_of_integer_to_bigint(TABLE, :id)
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod
  end

  def down
    return unless should_run?

    restore_conversion_of_integer_to_bigint(TABLE, :id)
  end

  def should_run?
    com_or_dev_or_test_but_not_jh?
  end
end
