# frozen_string_literal: true

class CleanupBigintConversionForSentNotifications < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  TABLE = :sent_notifications
  COLUMNS = [:id]

  def up
    cleanup_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    restore_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
