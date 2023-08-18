# frozen_string_literal: true

class RetryCleanupBigintConversionForEventsForGitlabCom < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  enable_lock_retries!

  TABLE = :events
  COLUMNS = [:target_id]

  # We first attempted to drop the temporary trigger and column at
  # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/126794
  def up
    return unless should_run?

    return unless column_exists?(TABLE, :target_id_convert_to_bigint)

    cleanup_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    return unless should_run?

    return if column_exists?(TABLE, :target_id_convert_to_bigint)

    restore_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  private

  def should_run?
    com_or_dev_or_test_but_not_jh?
  end
end
