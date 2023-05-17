# frozen_string_literal: true

class CleanupBigintConversionForSentNotifications < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  enable_lock_retries!

  TABLE = :sent_notifications
  COLUMNS = [:id]

  def up
    return unless should_run?

    cleanup_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    return unless should_run?

    restore_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def should_run?
    com_or_dev_or_test_but_not_jh?
  end
end
