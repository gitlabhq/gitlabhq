# frozen_string_literal: true

class CleanupBigintConversionForGeoEventLogGeoEventId < Gitlab::Database::Migration[2.2]
  enable_lock_retries!

  milestone '17.9'

  TABLE = :geo_event_log
  COLUMNS = [:geo_event_id]

  def up
    cleanup_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    restore_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
