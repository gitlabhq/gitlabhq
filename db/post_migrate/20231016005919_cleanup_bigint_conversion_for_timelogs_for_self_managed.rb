# frozen_string_literal: true

class CleanupBigintConversionForTimelogsForSelfManaged < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  enable_lock_retries!

  def up
    return if com_or_dev_or_test_but_not_jh?

    cleanup_conversion_of_integer_to_bigint(:timelogs, [:note_id])
  end

  def down
    # no-op
  end
end
