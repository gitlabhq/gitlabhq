# frozen_string_literal: true

class InitializeConversionOfGeoEventIdFromIntToBigint < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  disable_ddl_transaction!

  TABLE = :geo_event_log
  COLUMNS = %i[geo_event_id]

  def up
    initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    revert_initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
