# frozen_string_literal: true

class CleanupBigintConversionForMergeRequestMetricsForSelfHosts < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  enable_lock_retries!

  TABLE = :merge_request_metrics

  def up
    return if should_skip?
    return unless column_exists?(TABLE, :id_convert_to_bigint)

    # rubocop:disable Migration/WithLockRetriesDisallowedMethod
    with_lock_retries do
      cleanup_conversion_of_integer_to_bigint(TABLE, :id)
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod
  end

  def down
    return if should_skip?
    return if column_exists?(TABLE, :id_convert_to_bigint)

    restore_conversion_of_integer_to_bigint(TABLE, :id)
  end

  def should_skip?
    com_or_dev_or_test_but_not_jh?
  end
end
